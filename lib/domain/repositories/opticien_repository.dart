import 'package:opti_app/core/error/failures.dart';
import 'package:opti_app/domain/entities/Opticien.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:dartz/dartz.dart';

abstract class OpticienRepository {
  Future<List<Opticien>> getOpticiens();
}
