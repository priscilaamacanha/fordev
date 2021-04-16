import 'package:faker/faker.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:fordev/domain/usecases/usecases.dart';

import 'package:fordev/data/http/http.dart';
import 'package:fordev/data/usecases/usecases.dart';
import 'package:fordev/domain/helpers/helpers.dart';



// Test double
class HttpClientSpy extends Mock implements HttpClient {}

void main() {
  RemoteAuthentication sut;
  HttpClientSpy httpClient;
  String url;
  AuthenticationParams params;

  Map mockValidData() => {
        'accessToken': faker.guid.guid(),
        'name': faker.person.name()
      };

  PostExpectation mockRequest() =>  when(httpClient.request(url: anyNamed('url'), method: anyNamed('method'), body: anyNamed('body')));

  void mockHttpData(Map data) {
    mockRequest().thenAnswer((_) async => data);
  }

  void mockHttpError(HttpError error) {
    mockRequest().thenThrow(error);
  }

  setUp(() {
    httpClient = HttpClientSpy();
    //arrange
    url = faker.internet.httpUrl();
    sut = RemoteAuthentication(httpClient: httpClient, url: url); 
    params = AuthenticationParams(
      email: faker.internet.email(), 
      secret: faker.internet.password()
    );
    mockHttpData(mockValidData());
  });

  //Design Pattern AAA - triple A
  test('Should call HttpClient with correct values', () async {
    //act
    await sut.auth(params); 
    
    //assert
    verify(httpClient.request(
      url: url,
      method: 'post',
      body: {
        'email': params.email,
        'password': params.secret
      }
    ));
  });

  test('Should throw UnexpectedError if HttpClient returns 400 ', () async {
    mockHttpError(HttpError.badRequest);
    
    //act
    final future = sut.auth(params); 
    
    //assert
    expect(future, throwsA(DomainError.unexpected));
  });

  test('Should throw UnexpectedError if HttpClient returns 404 ', () async {
    mockHttpError(HttpError.notFound);
    
    //act
    final future = sut.auth(params); 
    
    //assert
    expect(future, throwsA(DomainError.unexpected));
  });

  test('Should throw UnexpectedError if HttpClient returns 500 ', () async {
    mockHttpError(HttpError.serverError);
    
    //act
    final future = sut.auth(params); 
    
    //assert
    expect(future, throwsA(DomainError.unexpected));
  });

  test('Should throw InvalidCredentialsError if HttpClient returns 401 ', () async {
    mockHttpError(HttpError.unauthorized);
    
    //act
    final future = sut.auth(params); 
    
    //assert
    expect(future, throwsA(DomainError.invalidCredentials));
  });

  test('Should return an Account if if HttpClient returns 200 ', () async {
    final validData = mockValidData();

    mockHttpData(validData);
    
    //act
    final account = await sut.auth(params); 
    
    //assert
    expect(account.token, validData['accessToken']);
  });

  test('Should throw UnexpectedError if if HttpClient returns 200 with invalid data', () async {
    mockHttpData({
      'ivalid_key': 'invalid_value'
    });
    
    //act
    final future = sut.auth(params); 
    
    //assert
    expect(future, throwsA(DomainError.unexpected));
  });
}