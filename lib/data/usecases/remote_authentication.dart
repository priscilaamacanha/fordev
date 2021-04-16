import 'package:meta/meta.dart';

import '../../domain/usecases/usecases.dart';
import '../../domain/helpers/domain_error.dart';
import '../../domain/entities/account_entity.dart';

import '../models/remote_account_model.dart';
import '../http/http.dart';

class RemoteAuthentication implements Authentication {
  final HttpClient httpClient;
  final String url;

  RemoteAuthentication({
    @required this.httpClient, 
    @required this.url,
  });

  Future<AccountEntity> auth(AuthenticationParams params) async {
    final body = RemoteAuthenticationParams.fromDomain(params).toJson();

    try{
      final httpResponse = await httpClient.request(
        url: url,
        method: 'post',
        body: body
      );

      return RemoteAccountModel
              .fromJson(httpResponse)
              .toEntity();
              
    } on HttpError catch(error) {
      throw error == HttpError.unauthorized 
          ? DomainError.invalidCredentials 
          : DomainError.unexpected;
    }
    
  }
}

class RemoteAuthenticationParams {
  final String email;
  final String password;

  RemoteAuthenticationParams({
    @required this.email, 
    @required this.password,
  });

  factory RemoteAuthenticationParams.fromDomain(AuthenticationParams domain) =>
    RemoteAuthenticationParams(email: domain.email, password: domain.secret);

  Map toJson() => {'email': email, 'password': password};
}