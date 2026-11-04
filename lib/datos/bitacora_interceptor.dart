import 'dart:developer' as developer;

import 'package:dio/dio.dart';

const _llaveCronometro = 'bitacora_cronometro';

// Registra método, ruta, código, tipo de error y tiempo.
// Nunca lo que buscó la persona: por eso usa options.path y no la URL completa.
class BitacoraInterceptor extends Interceptor {
  BitacoraInterceptor({void Function(String linea)? escribir})
    : _escribir = escribir ?? _escribirEnLog;

  final void Function(String linea) _escribir;

  static void _escribirEnLog(String linea) {
    developer.log(linea, name: 'recetario');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_llaveCronometro] = Stopwatch()..start();
    _escribir('→ ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final o = response.requestOptions;
    _escribir(
      '← ${response.statusCode} ${o.method} ${o.path} (${_milisegundos(o)} ms)',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final o = err.requestOptions;
    final codigo = err.response?.statusCode;
    final conCodigo = codigo == null ? '' : ' $codigo';
    _escribir(
      '✗ ${err.type.name}$conCodigo ${o.method} ${o.path} '
      '(${_milisegundos(o)} ms)',
    );
    handler.next(err);
  }

  int _milisegundos(RequestOptions o) {
    final cronometro = o.extra[_llaveCronometro];
    return cronometro is Stopwatch ? cronometro.elapsedMilliseconds : 0;
  }
}
