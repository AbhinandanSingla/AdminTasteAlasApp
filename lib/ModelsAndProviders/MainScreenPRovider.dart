import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_connection_checker/data_connection_checker.dart';
import 'package:flutter/cupertino.dart';
import 'package:tasteatlasadmin/ModelsAndProviders/connectivity_status.dart';

class MainScreenProvider extends ChangeNotifier {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool a = true;
  bool b = false;
  bool c = false;
  bool sucessDelivered = true;

  void refresh() {
    notifyListeners();
  }

  search(id) {
    final orders = _firestore.collection('currentOrder').snapshots();
    orders.forEach((element) {
      print(element);
    });
  }

  prepared(String orderId, String uid, Map productList) async {
    productList.forEach((key, value) {
      value["inProgress"] = false;
      print(value);
    });
    await _firestore
        .collection('currentOrder')
        .doc(orderId)
        .update({uid: productList});
  }

  delivered(String orderId, String uid, Map productList) async {
    sucessDelivered = false;
    notifyListeners();
    productList.forEach((key, value) {
      value["delivered"] = true;
      print(value);
    });
    await _firestore
        .collection('currentOrder')
        .doc(orderId)
        .update({uid: productList});
    String date =
        '${DateTime.now().day.toString()}|${DateTime.now().month.toString()}|${DateTime.now().year.toString()}';
    await _firestore.collection('orderHistory').doc(date).update({
      orderId: {uid: productList}
    }).catchError((e) {
      _firestore.collection('orderHistory').doc(date).set({
        orderId: {uid: productList}
      });
    });
    await _firestore.collection('currentOrder').doc(orderId).delete();
    try {
      await _firestore.collection('user').doc(uid).update({
        'currentOrder': FieldValue.arrayRemove([orderId])
      });
      sucessDelivered = true;
    } catch (e) {
      sucessDelivered = true;
    }

    notifyListeners();
  }
}

class CheckConnectionStatus {
  StreamController<ConnectionCheck> connectionChecker =
      StreamController<ConnectionCheck>();

  CheckConnectionStatus() {
    DataConnectionChecker().onStatusChange.listen((status) {
      var ConnectionStatus = _check(status);
      connectionChecker.add(ConnectionStatus);
    });
  }

  ConnectionCheck _check(DataConnectionStatus _status) {
    switch (_status) {
      case DataConnectionStatus.disconnected:
        return ConnectionCheck.Offline;
      case DataConnectionStatus.connected:
        return ConnectionCheck.Working;
      default:
        return ConnectionCheck.Offline;
    }
  }
}
