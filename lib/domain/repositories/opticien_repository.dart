import 'package:opti_app/domain/entities/Opticien.dart';

abstract class OpticienRepository {
  Future<List<Opticien>> getOpticiens();
  Future<void> addOpticien(Opticien opticien);
  Future<void> updateOpticien(String id, Opticien opticien);
  Future<void> deleteOpticien(String id);
}