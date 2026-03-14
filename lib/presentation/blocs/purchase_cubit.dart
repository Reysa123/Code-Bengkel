import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/purchase.dart';
import '../../data/models/purchase_item.dart';
import '../../data/repositories/purchase_repository.dart';

part 'purchase_state.dart';

class PurchaseCubit extends Cubit<PurchaseState> {
  final PurchaseRepository _repository = PurchaseRepository();

  PurchaseCubit() : super(PurchaseInitial());

  Future<void> createPurchase(
    Purchase purchase,
    List<PurchaseItem> items,String namaSupl
  ) async {
    emit(PurchaseLoading());
    try {
      final purchaseId = await _repository.createPurchaseWithItems(
        purchase,
        items,
        namaSupl,
      );

      // Update stok semua part yang dibeli
      for (var item in items) {
        await _repository.updatePartStock(item.partId, item.qty);
      }

      emit(PurchaseSuccess(purchaseId));
    } catch (e) {
      emit(PurchaseError(e.toString()));
    }
  }

  Future<void> loadAllPurchases() async {
    emit(PurchaseLoading());
    try {
      final purchases = await _repository.getAllPurchases();
      emit(PurchaseLoaded(purchases));
    } catch (e) {
      emit(PurchaseError(e.toString()));
    }
  }
}
