import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
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
  StreamController<ConnectivityStatus> connectionStatusController =
      StreamController<ConnectivityStatus>();
  StreamController<ConnectionCheck> connectionChecker =
      StreamController<ConnectionCheck>();

  CheckConnectionStatus() {
    DataConnectionChecker().onStatusChange.listen((status) {
      var ConnectionStatus = _check(status);
      connectionChecker.add(ConnectionStatus);
    });

    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      // convert our result
      var connectionStatus = _connectivityStatus(result);
      //Emit this to our stream
      connectionStatusController.add(connectionStatus);
    });
  }

// Converting result to enum
  ConnectivityStatus _connectivityStatus(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return ConnectivityStatus.Wifi;
      case ConnectivityResult.mobile:
        return ConnectivityStatus.Cellular;
      case ConnectivityResult.none:
        return ConnectivityStatus.Offline;
      default:
        return ConnectivityStatus.Offline;
    }
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
