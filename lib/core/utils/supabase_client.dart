import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../errors/exceptions.dart';
import '../../config/supabase_options.dart';

/// Service d'accès à Supabase encapsulant les opérations sur l'API
/// 
/// Cette classe fournit une interface unifiée pour interagir avec Supabase,
/// avec gestion des erreurs et conversions en exceptions métier.
class SupabaseClientService {
  // Singleton
  static final SupabaseClientService _instance = SupabaseClientService._internal();
  
  // Instance du client Supabase
  late final SupabaseClient _client;
  
  // Getters
  SupabaseClient get client => _client;
  GoTrueClient get auth => _client.auth;
  SupabaseStorage get storage => _client.storage;
  
  // Constructeur factory pour le singleton
  factory SupabaseClientService() {
    return _instance;
  }
  
  // Constructeur privé pour le singleton
  SupabaseClientService._internal() {
    _client = Supabase.instance.client;
  }
  
  /// Effectue une requête SELECT sur une table en gérant les erreurs
  /// 
  /// [table] : Nom de la table
  /// [columns] : Colonnes à sélectionner (par défaut toutes)
  /// [filters] : Fonction de filtre à appliquer à la requête
  Future<List<Map<String, dynamic>>> select({
    required String table,
    String columns = '*',
    Function(PostgrestFilterBuilder)? filters,
  }) async {
    try {
      var query = _client.from(table).select(columns);
      
      if (filters != null) {
        query = filters(query);
      }
      
      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw _handlePostgrestException(e, table: table);
    } on SocketException {
      throw NetworkException.noConnection();
    } on TimeoutException {
      throw NetworkException.timeout();
    } catch (e) {
      throw DatabaseException(
        'Erreur lors de la lecture des données de $table',
        code: 'db/unknown-error',
        cause: e,
      );
    }
  }
  
  /// Effectue une requête SELECT pour obtenir un seul enregistrement
  /// 
  /// [table] : Nom de la table
  /// [id] : Identifiant de l'enregistrement
  /// [columns] : Colonnes à sélectionner (par défaut toutes)
  /// [idField] : Nom du champ ID (par défaut 'id')
  Future<Map<String, dynamic>> selectById({
    required String table,
    required String id,
    String columns = '*',
    String idField = 'id',
  }) async {
    try {
      final response = await _client
          .from(table)
          .select(columns)
          .eq(idField, id)
          .single();
      
      return response;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw DatabaseException.notFound(entity: table);
      }
      throw _handlePostgrestException(e, table: table);
    } on SocketException {
      throw NetworkException.noConnection();
    } on TimeoutException {
      throw NetworkException.timeout();
    } catch (e) {
      throw DatabaseException(
        'Erreur lors de la lecture des données de $table',
        code: 'db/unknown-error',
        cause: e,
      );
    }
  }
  
  /// Effectue une requête INSERT sur une table
  /// 
  /// [table] : Nom de la table
  /// [data] : Données à insérer
  /// [returning] : Si true, retourne l'enregistrement inséré
  Future<Map<String, dynamic>?> insert({
    required String table,
    required Map<String, dynamic> data,
    bool returning = true,
  }) async {
    try {
      final response = await _client
          .from(table)
          .insert(data)
          .select(returning ? '*' : null);
      
      return returning && response.isNotEmpty ? response.first : null;
    } on PostgrestException catch (e) {
      throw _handlePostgrestException(e, table: table);
    } on SocketException {
      throw NetworkException.noConnection();
    } on TimeoutException {
      throw NetworkException.timeout();
    } catch (e) {
      throw DatabaseException(
        'Erreur lors de l\'insertion dans $table',
        code: 'db/unknown-error',
        cause: e,
      );
    }
  }
  
  /// Effectue une requête UPDATE sur une table
  /// 
  /// [table] : Nom de la table
  /// [id] : Identifiant de l'enregistrement à mettre à jour
  /// [data] : Données à mettre à jour
  /// [idField] : Nom du champ ID (par défaut 'id')
  /// [returning] : Si true, retourne l'enregistrement mis à jour
  Future<Map<String, dynamic>?> update({
    required String table,
    required String id,
    required Map<String, dynamic> data,
    String idField = 'id',
    bool returning = true,
  }) async {
    try {
      final response = await _client
          .from(table)
          .update(data)
          .eq(idField, id)
          .select(returning ? '*' : null);
      
      if (response.isEmpty) {
        throw DatabaseException.notFound(entity: table);
      }
      
      return returning ? response.first : null;
    } on PostgrestException catch (e) {
      throw _handlePostgrestException(e, table: table);
    } on SocketException {
      throw NetworkException.noConnection();
    } on TimeoutException {
      throw NetworkException.timeout();
    } catch (e) {
      if (e is DatabaseException) rethrow;
      
      throw DatabaseException(
        'Erreur lors de la mise à jour dans $table',
        code: 'db/unknown-error',
        cause: e,
      );
    }
  }
  
  /// Effectue une requête UPSERT (INSERT ou UPDATE) sur une table
  /// 
  /// [table] : Nom de la table
  /// [data] : Données à insérer ou mettre à jour
  /// [onConflict] : Colonne pour la détection de conflit
  /// [returning] : Si true, retourne l'enregistrement inséré/mis à jour
  Future<Map<String, dynamic>?> upsert({
    required String table,
    required Map<String, dynamic> data,
    String? onConflict,
    bool returning = true,
  }) async {
    try {
      var query = _client.from(table).upsert(data);
      
      if (onConflict != null) {
        query = query.onConflict(onConflict);
      }
      
      final response = await query.select(returning ? '*' : null);
      
      return returning && response.isNotEmpty ? response.first : null;
    } on PostgrestException catch (e) {
      throw _handlePostgrestException(e, table: table);
    } on SocketException {
      throw NetworkException.noConnection();
    } on TimeoutException {
      throw NetworkException.timeout();
    } catch (e) {
      throw DatabaseException(
        'Erreur lors de l\'upsert dans $table',
        code: 'db/unknown-error',
        cause: e,
      );
    }
  }
  
  /// Effectue une requête DELETE sur une table
  /// 
  /// [table] : Nom de la table
  /// [id] : Identifiant de l'enregistrement à supprimer
  /// [idField] : Nom du champ ID (par défaut 'id')
  /// [returning] : Si true, retourne l'enregistrement supprimé
  Future<Map<String, dynamic>?> delete({
    required String table,
    required String id,
    String idField = 'id',
    bool returning = false,
  }) async {
    try {
      final response = await _client
          .from(table)
          .delete()
          .eq(idField, id)
          .select(returning ? '*' : null);
      
      if (response.isEmpty && returning) {
        throw DatabaseException.notFound(entity: table);
      }
      
      return returning && response.isNotEmpty ? response.first : null;
    } on PostgrestException catch (e) {
      throw _handlePostgrestException(e, table: table);
    } on SocketException {
      throw NetworkException.noConnection();
    } on TimeoutException {
      throw NetworkException.timeout();
    } catch (e) {
      if (e is DatabaseException) rethrow;
      
      throw DatabaseException(
        'Erreur lors de la suppression dans $table',
        code: 'db/unknown-error',
        cause: e,
      );
    }
  }
  
  /// Exécute une procédure stockée (fonction RPC)
  /// 
  /// [functionName] : Nom de la fonction à appeler
  /// [params] : Paramètres à passer à la fonction
  Future<dynamic> rpc({
    required String functionName,
    Map<String, dynamic>? params,
  }) async {
    try {
      final response = await _client.rpc(
        functionName,
        params: params,
      );
      
      return response;
    } on PostgrestException catch (e) {
      throw _handlePostgrestException(e, procedure: functionName);
    } on SocketException {
      throw NetworkException.noConnection();
    } on TimeoutException {
      throw NetworkException.timeout();
    } catch (e) {
      throw DatabaseException(
        'Erreur lors de l\'appel à la procédure $functionName',
        code: 'db/rpc-error',
        cause: e,
      );
    }
  }
  
  /// Télécharge un fichier vers le stockage Supabase
  /// 
  /// [bucket] : Nom du bucket de stockage
  /// [path] : Chemin de destination dans le bucket
  /// [file] : Fichier à télécharger
  /// [fileOptions] : Options supplémentaires pour le fichier
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required File file,
    FileOptions? fileOptions,
  }) async {
    try {
      final fileExt = file.path.split('.').last;
      final fileName = path.isEmpty ? '${DateTime.now().millisecondsSinceEpoch}.$fileExt' : path;
      
      await _client.storage.from(bucket).upload(
        fileName,
        file,
        fileOptions: fileOptions,
      );
      
      return _client.storage.from(bucket).getPublicUrl(fileName);
    } on StorageException catch (e) {
      throw _handleStorageException(e, bucket: bucket);
    } on SocketException {
      throw NetworkException.noConnection();
    } on TimeoutException {
      throw NetworkException.timeout();
    } catch (e) {
      throw StorageException(
        'Erreur lors du téléchargement du fichier vers $bucket',
        code: 'storage/upload-error',
        cause: e,
      );
    }
  }
  
  /// Télécharge un fichier depuis le stockage Supabase
  /// 
  /// [bucket] : Nom du bucket de stockage
  /// [path] : Chemin du fichier dans le bucket
  Future<Uint8List> downloadFile({
    required String bucket,
    required String path,
  }) async {
    try {
      final data = await _client.storage.from(bucket).download(path);
      return data;
    } on StorageException catch (e) {
      throw _handleStorageException(e, bucket: bucket);
    } on SocketException {
      throw NetworkException.noConnection();
    } on TimeoutException {
      throw NetworkException.timeout();
    } catch (e) {
      throw StorageException(
        'Erreur lors du téléchargement du fichier depuis $bucket',
        code: 'storage/download-error',
        cause: e,
      );
    }
  }
  
  /// Supprime un fichier du stockage Supabase
  /// 
  /// [bucket] : Nom du bucket de stockage
  /// [path] : Chemin du fichier dans le bucket
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await _client.storage.from(bucket).remove([path]);
    } on StorageException catch (e) {
      throw _handleStorageException(e, bucket: bucket);
    } on SocketException {
      throw NetworkException.noConnection();
    } on TimeoutException {
      throw NetworkException.timeout();
    } catch (e) {
      throw StorageException(
        'Erreur lors de la suppression du fichier depuis $bucket',
        code: 'storage/delete-error',
        cause: e,
      );
    }
  }
  
  /// Obtient l'URL publique d'un fichier
  /// 
  /// [bucket] : Nom du bucket de stockage
  /// [path] : Chemin du fichier dans le bucket
  String getPublicUrl({
    required String bucket,
    required String path,
  }) {
    try {
      return _client.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      throw StorageException(
        'Erreur lors de la génération de l\'URL publique',
        code: 'storage/url-error',
        cause: e,
      );
    }
  }
  
  /// Vérifie si un enregistrement existe
  /// 
  /// [table] : Nom de la table
  /// [id] : Identifiant de l'enregistrement
  /// [idField] : Nom du champ ID (par défaut 'id')
  Future<bool> exists({
    required String table,
    required String id,
    String idField = 'id',
  }) async {
    try {
      final response = await _client
          .from(table)
          .select('count', { 'count': 'exact', 'head': true })
          .eq(idField, id);
      
      return (response.count ?? 0) > 0;
    } on PostgrestException catch (e) {
      throw _handlePostgrestException(e, table: table);
    } on SocketException {
      throw NetworkException.noConnection();
    } on TimeoutException {
      throw NetworkException.timeout();
    } catch (e) {
      throw DatabaseException(
        'Erreur lors de la vérification de l\'existence dans $table',
        code: 'db/unknown-error',
        cause: e,
      );
    }
  }
  
  /// Effectue une requête COUNT sur une table
  /// 
  /// [table] : Nom de la table
  /// [filters] : Fonction de filtre à appliquer à la requête
  Future<int> count({
    required String table,
    Function(PostgrestFilterBuilder)? filters,
  }) async {
    try {
      var query = _client
          .from(table)
          .select('count', { 'count': 'exact', 'head': true });
      
      if (filters != null) {
        query = filters(query);
      }
      
      final response = await query;
      return response.count ?? 0;
    } on PostgrestException catch (e) {
      throw _handlePostgrestException(e, table: table);
    } on SocketException {
      throw NetworkException.noConnection();
    } on TimeoutException {
      throw NetworkException.timeout();
    } catch (e) {
      throw DatabaseException(
        'Erreur lors du comptage des enregistrements dans $table',
        code: 'db/unknown-error',
        cause: e,
      );
    }
  }
  
  /// S'abonne aux modifications d'une table
  /// 
  /// [table] : Nom de la table
  /// [event] : Type d'événement à écouter (INSERT, UPDATE, DELETE, *)
  /// [callback] : Fonction de rappel appelée à chaque événement
  /// Retourne un canal de temps réel à utiliser pour se désabonner
  RealtimeChannel subscribe({
    required String table,
    String event = '*',
    required Function(Map<String, dynamic>) callback,
  }) {
    final channel = _client
        .channel('public:$table')
        .on(RealtimeListenTypes.postgresChanges,
            ChannelFilter(event: event, schema: 'public', table: table),
            (payload, [ref]) {
              final data = Map<String, dynamic>.from(payload);
              callback(data);
            });
    
    channel.subscribe();
    return channel;
  }
  
  /// Se désabonne des modifications d'une table
  /// 
  /// [channel] : Canal de temps réel à fermer
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await channel.unsubscribe();
  }
  
  /// Convertit une exception Postgrest en exception métier
  AppException _handlePostgrestException(PostgrestException e, {String? table, String? procedure}) {
    final operation = table != null ? 'opération sur $table' : 
                     procedure != null ? 'appel à $procedure' : 
                     'opération sur la base de données';
    
    // Codes d'erreur communs de PostgreSQL
    switch (e.code) {
      case '23505': // Violation de contrainte unique
        return DatabaseException.duplicate(
          entity: table,
        );
      case '23503': // Violation de contrainte de clé étrangère
        return DatabaseException.foreignKeyConstraint(
          cause: e,
        );
      case '23514': // Violation de contrainte check
      case '23502': // Violation de contrainte not null
        return ValidationException(
          'Données invalides pour $operation',
          code: 'db/constraint-violation',
          cause: e,
        );
      case '42P01': // Table inexistante
        return DatabaseException(
          'Table non trouvée',
          code: 'db/table-not-found',
          cause: e,
        );
      case '42501': // Privilèges insuffisants
        return PermissionException.accessDenied();
      case 'PGRST116': // Aucun résultat trouvé pour .single()
        return DatabaseException.notFound(
          entity: table,
        );
      default:
        // Gestion générique
        if (e.code?.startsWith('PGRST') ?? false) {
          return DatabaseException(
            'Erreur PostgREST: ${e.message}',
            code: 'db/postgrest-error',
            cause: e,
          );
        }
        
        return DatabaseException(
          'Erreur PostgreSQL lors de $operation',
          code: 'db/postgres-error',
          cause: e,
        );
    }
  }
  
  /// Convertit une exception Storage en exception métier
  AppException _handleStorageException(StorageException e, {String? bucket}) {
    final location = bucket != null ? 'sur $bucket' : 'sur le stockage';
    
    // Traitement basé sur le message d'erreur
    if (e.message.contains('not found')) {
      return StorageException(
        'Fichier ou bucket non trouvé $location',
        code: 'storage/not-found',
        cause: e,
      );
    } else if (e.message.contains('access denied') || e.message.contains('unauthorized')) {
      return PermissionException.accessDenied();
    } else if (e.message.contains('limit') || e.message.contains('too large')) {
      return StorageException.fileTooLarge(100); // Valeur par défaut de 100 MB
    }
    
    return StorageException(
      'Erreur de stockage $location: ${e.message}',
      code: 'storage/unknown-error',
      cause: e,
    );
  }
}