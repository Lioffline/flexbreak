import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
import 'mocks/firestore_mock.dart';

void main() {
  late MockFirestore mockFirestore;
  late MockCollectionReference mockUsersCollection;
  late MockDocumentReference mockUserDocument;
  late MockDocumentSnapshot mockUserSnapshot;

  setUpAll(() {
    // Настройка fallback значений
    registerFallbackValue(MockDocumentReference());
    registerFallbackValue(MockCollectionReference());
  });

  setUp(() {
    mockFirestore = MockFirestore();
    mockUsersCollection = MockCollectionReference();
    mockUserDocument = MockDocumentReference();
    mockUserSnapshot = MockDocumentSnapshot();

    when(() => mockFirestore.collection(any())).thenReturn(mockUsersCollection);
    when(() => mockUsersCollection.doc(any())).thenReturn(mockUserDocument);
    when(() => mockUserDocument.get()).thenAnswer((_) async => mockUserSnapshot);

    when(() => mockUserSnapshot.exists).thenReturn(true);
    when(() => mockUserSnapshot.data()).thenReturn({
      'Name': 'Test User',
      'mail': 'test@example.com'
    });
    when(() => mockUserSnapshot.id).thenReturn('testUser');
    when(() => mockUserDocument.id).thenReturn('testUser');
  });

  test('Проверка полной цепочки вызовов Firestore', () async {
    final doc = await mockFirestore.collection('Users').doc('testUser').get();
    
    expect(doc.exists, isTrue);
    expect(doc.id, 'testUser');
    expect(doc.data()?['Name'], 'Test User');
    
    verify(() => mockFirestore.collection('Users')).called(1);
    verify(() => mockUsersCollection.doc('testUser')).called(1);
    verify(() => mockUserDocument.get()).called(1);
  });

  test('Проверка получения несуществующего документа', () async {
    when(() => mockUserSnapshot.exists).thenReturn(false);
    when(() => mockUserSnapshot.data()).thenReturn(null);

    final doc = await mockFirestore.collection('Users').doc('nonExistingUser').get();

    expect(doc.exists, isFalse);
    expect(doc.data(), isNull);
  });

  test('Проверка получения документа c другими данными', () async {
    when(() => mockUserSnapshot.exists).thenReturn(true);
    when(() => mockUserSnapshot.data()).thenReturn({
      'Name': 'Another User',
      'mail': 'another@example.com'
    });

    final doc = await mockFirestore.collection('Users').doc('anotherUser').get();

    expect(doc.exists, isTrue);
    expect(doc.data()?['Name'], 'Another User');
    expect(doc.data()?['mail'], 'another@example.com');
  });
}