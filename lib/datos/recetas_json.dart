import '../dominio/receta.dart';

Dificultad dificultadDesdeTexto(Object? valor) {
  return switch (valor) {
    'Easy' => Dificultad.facil,
    'Medium' => Dificultad.media,
    'Hard' => Dificultad.dificil,
    _ => Dificultad.desconocida,
  };
}

Receta recetaDesdeJson(Map<String, dynamic> json) {
  switch (json) {
    case {
      'id': int id,
      'name': String nombre,
      'cuisine': String cocina,
      'prepTimeMinutes': int minutosPreparacion,
      'cookTimeMinutes': int minutosCoccion,
      'servings': int porciones,
      'rating': num calificacion,
    }:
      return Receta(
        id: id,
        nombre: nombre,
        cocina: cocina,
        dificultad: dificultadDesdeTexto(json['difficulty']),
        minutosPreparacion: minutosPreparacion,
        minutosCoccion: minutosCoccion,
        porciones: porciones,
        calificacion: calificacion.toDouble(),
        etiquetas: _listaDeTextos(json, 'tags'),
        ingredientes: _listaDeTextos(json, 'ingredients'),
      );
    default:
      throw const FormatException('La receta no tiene los campos obligatorios');
  }
}

PaginaRecetas paginaDesdeJson(Map<String, dynamic> json) {
  switch (json) {
    case {'recipes': List recetas, 'total': int total}:
      final lista = <Receta>[];
      for (final elemento in recetas) {
        if (elemento is! Map<String, dynamic>) {
          throw const FormatException('Un elemento de recipes no es un objeto');
        }
        lista.add(recetaDesdeJson(elemento));
      }
      return PaginaRecetas(recetas: lista, total: total);
    default:
      throw const FormatException('La página no tiene recipes y total');
  }
}

List<String> _listaDeTextos(Map<String, dynamic> json, String llave) {
  final valor = json[llave];
  if (valor == null) return const [];
  if (valor is! List) {
    throw FormatException('$llave no es una lista');
  }
  final textos = <String>[];
  for (final elemento in valor) {
    if (elemento is! String) {
      throw FormatException('$llave tiene un elemento que no es texto');
    }
    textos.add(elemento);
  }
  return textos;
}
