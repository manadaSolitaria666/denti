// lib/core/constants/api_constants.dart

// IMPORTANTE: Estas claves son sensibles.
// En un proyecto real, NO las incluyas directamente en el código fuente que subes a repositorios públicos.
// Considera usar variables de entorno (flutter_dotenv package) o un sistema de configuración seguro.
// Para desarrollo, puedes ponerlas aquí temporalmente.

class ApiConstants {
  // Reemplaza con tu API Key de Gemini
  static const String geminiApiKey = "AIzaSyDAQ5n5-ZzPXk1uu00liSb8nVnRQWZsYE8"; 

  // Reemplaza con tu API Key de Google Maps Platform (habilitar Places API y Maps SDK for Android/iOS)
  static const String googleMapsApiKey = "AIzaSyDyWX2h8wtfnhnsGvLL826fNg538smiRPg";

  // Reemplaza con la URL base de la API de tu blog
  // Ejemplo: "[https://miapi.com/api](https://miapi.com/api)" o "http://localhost:3000/api" si es local
  static const String blogApiBaseUrl = "URL_DE_TU_API_DE_BLOG_AQUI"; 
                                       // Si no tienes una API de blog aún, puedes dejarla vacía
                                       // o usar un mock server como [https://jsonplaceholder.typicode.com/posts](https://jsonplaceholder.typicode.com/posts)
                                       // para pruebas, ajustando el modelo BlogPostModel.
}
