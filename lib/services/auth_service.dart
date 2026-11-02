import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream de l'état de connexion
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Inscription avec email
  Future<void> registerWithEmail(String email, String password, String username) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user!.sendEmailVerification();
      await _firestore.collection('users').doc(credential.user!.uid).set(
        UserModel(
          uid: credential.user!.uid,
          email: email,
          username: username,
        ).toMap(),
      );
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Erreur inscription');
    }
  }

  // Connexion avec email
  Future<void> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!credential.user!.emailVerified) {
        await _auth.signOut();
        throw Exception('Vérifie ton email avant de te connecter');
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Erreur connexion');
    }
  }

  // Connexion avec Google
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Connexion Google annulée');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );


      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      // Crée le profil si c'est la première connexion
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await _firestore.collection('users').doc(user.uid).set(
          UserModel(
            uid: user.uid,
            email: user.email ?? '',
            username: user.displayName ?? 'User',
            photoUrl: user.photoURL,
          ).toMap(),
        );
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Erreur Google');
    } catch (e) {
      rethrow;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Envoyer le code SMS
Future<void> sendPhoneCode({
  required String phoneNumber,
  required Function(String verificationId) onCodeSent,
  required Function(String error) onError,
}) async {
  await _auth.verifyPhoneNumber(
    phoneNumber: phoneNumber,
    verificationCompleted: (PhoneAuthCredential credential) async {
      await _auth.signInWithCredential(credential);
    },
    verificationFailed: (FirebaseAuthException e) {
      onError(e.message ?? 'Erreur vérification');
    },
    codeSent: (String verificationId, int? resendToken) {
      onCodeSent(verificationId);
    },
    codeAutoRetrievalTimeout: (String verificationId) {},
  );
}

// Vérifier le code SMS
Future<void> verifyPhoneCode({
  required String verificationId,
  required String smsCode,
}) async {
  try {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;

    // Crée le profil si première connexion
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      await _firestore.collection('users').doc(user.uid).set(
        UserModel(
          uid: user.uid,
          email: '',
          username: user.phoneNumber ?? 'User',
          phoneNumber: user.phoneNumber,
        ).toMap(),
      );
    }
  } on FirebaseAuthException catch (e) {
    throw Exception(e.message ?? 'Code invalide');
  }
}
}