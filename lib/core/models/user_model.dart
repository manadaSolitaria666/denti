// lib/core/models/user_model.dart
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel extends Equatable {
  final String id;
  final String? email;
  final String? name;
  final String? surname;
  final int? age;
  final String? sex; // Podría ser un enum: Sex.male, Sex.female, Sex.other
  final bool termsAccepted;
  final Timestamp? createdAt;

  const UserModel({
    required this.id,
    this.email,
    this.name,
    this.surname,
    this.age,
    this.sex,
    this.termsAccepted = false,
    this.createdAt,
  });

  // Factory constructor para crear desde un DocumentSnapshot de Firestore
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      id: doc.id,
      email: data['email'] as String?,
      name: data['name'] as String?,
      surname: data['surname'] as String?,
      age: data['age'] as int?,
      sex: data['sex'] as String?,
      termsAccepted: data['termsAccepted'] as bool? ?? false,
      createdAt: data['createdAt'] as Timestamp?,
    );
  }

  // Método para convertir a un Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (surname != null) 'surname': surname,
      if (age != null) 'age': age,
      if (sex != null) 'sex': sex,
      'termsAccepted': termsAccepted,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(), // Establece la hora del servidor al crear
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? surname,
    int? age,
    String? sex,
    bool? termsAccepted,
    Timestamp? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      surname: surname ?? this.surname,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, email, name, surname, age, sex, termsAccepted, createdAt];
}

enum Sex { male, female, other }