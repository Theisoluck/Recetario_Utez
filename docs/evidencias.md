# Evidencias — Recetario UTEZ

**Nombre:** Axel Solano Castillo
**Matrícula:** 20233TN131
**Fecha:** 03/11/2026
**Dispositivo donde se probó:** Chrome 157 en Windows 11 (`flutter run -d web-server`, ventana de 412 x 860)

## 1. Del JSON a Dart

| JSON | Campo Dart | Tipo | Regla (obligatorio, tolerado, valor por defecto) |
|---|---|---|---|
| `id` | `Receta.id` | `int` | Obligatorio. Si falta o no es entero: `FormatException`. |
| `name` | `Receta.nombre` | `String` | Obligatorio. Si falta o no es texto: `FormatException`. |
| `cuisine` | `Receta.cocina` | `String` | Obligatorio. Si falta o no es texto: `FormatException`. |
| `difficulty` | `Receta.dificultad` | `Dificultad` | Tolerado. `Easy`, `Medium` y `Hard` se traducen. Cualquier otro valor, `null` o un número queda en `Dificultad.desconocida` ("Sin dato"). Nunca lanza error. |
| `prepTimeMinutes` | `Receta.minutosPreparacion` | `int` | Obligatorio. Si falta o no es entero: `FormatException`. |
| `cookTimeMinutes` | `Receta.minutosCoccion` | `int` | Obligatorio. Si falta o no es entero: `FormatException`. |
| `servings` | `Receta.porciones` | `int` | Obligatorio. Si falta o no es entero (por ejemplo `"4"`): `FormatException`. |
| `rating` | `Receta.calificacion` | `double` | Obligatorio. Acepta entero (`5`) o decimal (`4.6`) porque se lee como `num` y se guarda con `.toDouble()`. |
| `tags` | `Receta.etiquetas` | `List<String>` | Opcional. Si falta: lista vacía. Si no es lista o un elemento no es texto: `FormatException`. |
| `ingredients` | `Receta.ingredientes` | `List<String>` | Opcional. Si falta: lista vacía. Si no es lista o un elemento no es texto: `FormatException`. |
| `recipes` | `PaginaRecetas.recetas` | `List<Receta>` | Obligatorio. Cada elemento debe ser un objeto y se convierte con `recetaDesdeJson`. Una lista vacía es válida. |
| `total` | `PaginaRecetas.total` | `int` | Obligatorio. Si falta: `FormatException`. |
| (calculado) | `Receta.tiempoTotal` | `int` | No viene en el JSON: es `minutosPreparacion + minutosCoccion`. |
| (calculado) | `Receta.esRapida` | `bool` | No viene en el JSON: `tiempoTotal <= 30`. |

Los demás campos del JSON (`instructions`, `image`, `userId`, `mealType`, `skip`, `limit`, etc.) se ignoran.

## 2. Escenarios probados con el servicio real

| Escenario | Cómo lo provoqué | Qué vio la persona | Línea de la bitácora | Captura | Prueba del kit que lo cubre |
|---|---|---|---|---|---|
| Éxito | Escribí `chicken` y toqué **Buscar recetas**, sin cambios en `main.dart`. | El botón se desactivó con el indicador de carga y luego apareció "Mostrando 8 de 8 recetas · Rápidas: 1" con las tarjetas (por ejemplo "Chicken Alfredo Pasta", "Italian · Media", "Tiempo: 35 min · Porciones: 4", "Calificación: 4.9"). | `← 200 GET /recipes/search (202 ms)` | [1_exito.png](capturas/1_exito.png) | `etapa3_datos_test.dart`: "200 → PaginaRecetas". `etapa5_vistas_test.dart`: "texto + botón → indicador y botón apagado → tarjetas". |
| Vacío | Escribí `zzzz` y toqué **Buscar recetas**, sin cambios en `main.dart`. | "No encontramos recetas para "zzzz"." | `← 200 GET /recipes/search (193 ms)` | [2_vacio.png](capturas/2_vacio.png) | `etapa3_datos_test.dart`: "200 sin resultados → página vacía". `etapa4_viewmodel_test.dart`: "sin resultados → Vacias, recordando qué se buscó". `etapa5_vistas_test.dart`: "vacío con texto dice qué se buscó; sin texto, otro mensaje". |
| Error del servidor | Cambio temporal A en `main.dart` (interceptor que cambia la ruta a `/http/503`) y busqué `chicken`. | "El recetario no está disponible (503). Intenta más tarde." y el botón **Reintentar**. | `✗ badResponse 503 GET /http/503 (255 ms)` | [3_error_servidor.png](capturas/3_error_servidor.png) | `etapa3_datos_test.dart`: "503 → ErrorDelServidor(503)" y "en un error escribe una línea con ✗ y el código". `etapa4_viewmodel_test.dart`: "FallaRed → Fallidas con el mensaje de mensajePara". |
| Sin red | Con la app normal, puse la red de Chrome en **Offline** desde DevTools (el navegador queda sin conexión) y busqué `chicken`. | "Sin conexión. Revisa tu red e intenta de nuevo." y el botón **Reintentar**. | `✗ connectionError GET /recipes/search (68 ms)` | [4_sin_red.png](capturas/4_sin_red.png) | `etapa3_datos_test.dart`: "sin red → SinConexion". `etapa5_vistas_test.dart`: "error → mensaje y Reintentar repite la misma búsqueda". |
| Tiempo agotado | Cambio temporal B en `main.dart` (`delay` de 5000 ms y timeouts de 2 s) y busqué `chicken`. | "El recetario tardó demasiado en responder. Intenta de nuevo." y el botón **Reintentar**. | `✗ connectionTimeout GET /recipes/search (2080 ms)` | [5_tiempo_agotado.png](capturas/5_tiempo_agotado.png) | `etapa3_datos_test.dart`: "connectTimeout → TiempoAgotado" y "receiveTimeout → TiempoAgotado". |

En web el timeout aparece como `connectionTimeout` y no como `receiveTimeout`. Es lo normal en el navegador, y los dos se traducen a `TiempoAgotado`. Al terminar regresé `main.dart` a la versión de la etapa 5.

## 3. Preguntas de reflexión

1. **¿En qué se diferencian el escenario "Error del servidor" y "Sin red" desde el punto de vista de HTTP?**
   En el error del servidor sí hubo una conversación HTTP completa: la petición llegó a DummyJSON y este respondió con un código de estado 503. Por eso Dio lo marca como `badResponse` y trae el código. En "Sin red" nunca hubo respuesta HTTP: la conexión no se pudo abrir, así que no existe código de estado y Dio lo marca como `connectionError`. El primero depende del servidor y puede resolverse más tarde. El segundo depende de la red de la persona.

2. **¿Por qué "Vacío" no es un error?**
   Porque el servidor respondió bien: código 200 y un JSON válido con `"recipes": []`. La búsqueda funcionó y el resultado correcto es que no hay coincidencias. Por eso la app muestra un mensaje que dice qué se buscó, en lugar de un mensaje de falla con **Reintentar**, porque reintentar daría el mismo resultado.

3. **La búsqueda de la persona viaja en la query. ¿Por qué tu bitácora no la escribe?**
   Porque lo que escribe la persona es un dato suyo y la bitácora no debe guardarlo ni exponerlo. Por eso la bitácora usa `options.path` (`/recipes/search`) y no la URL completa ni los parámetros de la query. Solo registra método, ruta, código, tipo de error y tiempo, que basta para diagnosticar.

4. **Si DummyJSON cambiara `rating` por `score`, ¿qué archivos tendrías que modificar y por qué solo esos?**
   Solo `lib/datos/recetas_json.dart`: cambiar la llave `'rating'` por `'score'` en el patrón de `recetaDesdeJson`. Es el único archivo que conoce los nombres de las llaves del JSON. El dominio usa `calificacion`, y el ViewModel y las vistas solo conocen `Receta`, así que no se enteran del cambio. Además, los datos de ejemplo de las pruebas del kit tendrían que usar la nueva llave, pero esos no los edito yo.
