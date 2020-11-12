import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:tasteatlasadmin/ModelsAndProviders/MainScreenPRovider.dart';
import 'package:tasteatlasadmin/TopContainer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MainScreenProvider>(
            create: (context) => MainScreenProvider())
      ],
      child: MaterialApp(home: MyHomePage()),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<QueryDocumentSnapshot> Orders = [];
  double totalAmount = 0;
  List ready = [];

  @override
  Widget build(BuildContext context) {
    MainScreenProvider _mainScreenProvider =
        Provider.of<MainScreenProvider>(context);

    final size = MediaQuery.of(context).size;
    print(_mainScreenProvider.a);
    return Scaffold(
      backgroundColor: Color(0xFFF3F4F8),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              delegate: TopContainer(minExtent: 200, maxExtent: 250),
            ),
            SliverToBoxAdapter(
              child: Consumer<MainScreenProvider>(
                builder: (BuildContext context, MainScreenProvider _provider,
                        Widget child) =>
                    Visibility(
                  visible: _provider.a,
                  child: child,
                ),
                child: StreamBuilder(
                  stream: _firestore.collection('currentOrder').snapshots(),
                  builder:
                      (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                    if (snapshot.data == null) {
                      return Text('Loading ....');
                    }
                    Orders.clear();
                    snapshot.data.docs.forEach((element) {
                      Orders.add(element);
                    });
                    return ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      scrollDirection: Axis.vertical,
                      itemCount: Orders.length,
                      shrinkWrap: true,
                      itemBuilder: (BuildContext context, int index) {
                        Map abc = Orders[index].data().values.first;
                        String uid = Orders[index].data().keys.first;
                        Timestamp dateTime = abc.values.first['orderedTime'];
                        bool inProgress = abc.values.first['inProgress'];
                        print(inProgress);
                        totalAmount = 0;
                        double tax = 5 / 100;
                        int CartTotal = 0;
                        abc.forEach((key, value) {
                          CartTotal += value['price'] * value['quantity'];
                        });
                        tax =
                            double.parse((CartTotal * tax).toStringAsFixed(2));
                        totalAmount = CartTotal + tax;
                        return Visibility(
                          visible: inProgress,
                          child: Container(
                            padding: EdgeInsets.only(right: 20, left: 20),
                            height: size.height * 0.4,
                            margin: EdgeInsets.only(
                                top: 10, bottom: 10, left: 20, right: 20),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'OrderID : ${Orders[index].id.toString()} | ${dateTime.toDate().hour}:${dateTime.toDate().minute} ',
                                  style: TextStyle(
                                    fontSize: 20,
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                      border: Border.symmetric(
                                          horizontal: BorderSide(
                                    color: Colors.grey,
                                    width: 2,
                                  ))),
                                  child: ListView.builder(
                                    physics: NeverScrollableScrollPhysics(),
                                    padding:
                                        EdgeInsets.only(top: 20, bottom: 20),
                                    itemCount: abc.length,
                                    shrinkWrap: true,
                                    itemBuilder:
                                        (BuildContext context, int index2) {
                                      print(index2);
                                      String key = abc.keys.elementAt(
                                          index2); // key = product id
                                      return Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${abc[key]['quantity']} X ${abc[key]['name']}',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              Text('Rs ${abc[key]['price']}')
                                            ],
                                          ),
                                          SizedBox(
                                            height: 10,
                                          )
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                Text('Total bill : Rs ${totalAmount}'),
                                InkWell(
                                  onTap: () {
                                    _mainScreenProvider.prepared(
                                        Orders[index].id.toString(), uid, abc);
                                  },
                                  child: Container(
                                    height: 60,
                                    width: size.width - 50,
                                    decoration: BoxDecoration(
                                        color: Colors.deepOrange,
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: Center(
                                        child: inProgress
                                            ? Text(
                                                'Prepared',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 18),
                                              )
                                            : Text('Delivery Pending')),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Consumer<MainScreenProvider>(
                builder: (BuildContext context, MainScreenProvider _provider,
                        Widget child) =>
                    Visibility(
                  visible: _provider.b,
                  child: child,
                ),
                child: Stack(
                  children: [
                    Consumer<MainScreenProvider>(
                      builder: (BuildContext context,
                              MainScreenProvider mainScreenValue,
                              Widget child) =>
                          Visibility(
                        visible: mainScreenValue.sucessDelivered,
                        child: child,
                      ),
                      child: StreamBuilder(
                        stream:
                            _firestore.collection('currentOrder').snapshots(),
                        builder: (BuildContext context,
                            AsyncSnapshot<dynamic> snapshot) {
                          if (snapshot.data == null) {
                            return Text('Loading ....');
                          }
                          Orders.clear();
                          snapshot.data.docs.forEach((element) {
                            Orders.add(element);
                          });

                          return ListView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            scrollDirection: Axis.vertical,
                            itemCount: Orders.length,
                            shrinkWrap: true,
                            itemBuilder: (BuildContext context, int index) {
                              Map abc = Orders[index].data().values.first;
                              String uid = Orders[index].data().keys.first;
                              Timestamp dateTime =
                                  abc.values.first['orderedTime'];
                              bool delivered = !abc.values.first['inProgress'];
                              print(delivered);
                              totalAmount = 0;
                              double tax = 5 / 100;
                              int CartTotal = 0;
                              abc.forEach((key, value) {
                                CartTotal += value['price'] * value['quantity'];
                              });
                              tax = double.parse(
                                  (CartTotal * tax).toStringAsFixed(2));
                              totalAmount = CartTotal + tax;
                              return Visibility(
                                visible: delivered,
                                child: Container(
                                  padding: EdgeInsets.only(right: 20, left: 20),
                                  height: size.height * 0.4,
                                  margin: EdgeInsets.only(
                                      top: 10, bottom: 10, left: 20, right: 20),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'OrderID : ${Orders[index].id.toString()} | ${dateTime.toDate().hour}:${dateTime.toDate().minute} ',
                                        style: TextStyle(
                                          fontSize: 20,
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                            border: Border.symmetric(
                                                horizontal: BorderSide(
                                          color: Colors.grey,
                                          width: 2,
                                        ))),
                                        child: ListView.builder(
                                          physics:
                                              NeverScrollableScrollPhysics(),
                                          padding: EdgeInsets.only(
                                              top: 20, bottom: 20),
                                          itemCount: abc.length,
                                          shrinkWrap: true,
                                          itemBuilder: (BuildContext context,
                                              int index2) {
                                            print(index2);
                                            String key = abc.keys.elementAt(
                                                index2); // key = product id
                                            return Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      '${abc[key]['quantity']} X ${abc[key]['name']}',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Text(
                                                        'Rs ${abc[key]['price']}')
                                                  ],
                                                ),
                                                SizedBox(
                                                  height: 10,
                                                )
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                      Text('Total bill : Rs ${totalAmount}'),
                                      InkWell(
                                        onTap: () {
                                          _mainScreenProvider.delivered(
                                              Orders[index].id.toString(),
                                              uid,
                                              abc);
                                        },
                                        child: Container(
                                          height: 60,
                                          width: size.width - 50,
                                          decoration: BoxDecoration(
                                              color: Colors.deepOrange,
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          child: Center(
                                              child: Text(
                                            'Delivered',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 18),
                                          )),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Consumer<MainScreenProvider>(
                      builder: (BuildContext context,
                              MainScreenProvider providervalue, Widget child) =>
                          Visibility(
                        visible: !providervalue.sucessDelivered,
                        child: Container(
                          child:
                              Lottie.asset('assets/animations/delivered.json'),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
