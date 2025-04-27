/// This file provides an interface to Firebase Authentication, allowing users to sign in
/// using email/password or Google Sign-In. This is also where we define our sign in, sign out,
/// and our create account method.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Encapsulate the functionality of the Firebase Authentication API
class FirebaseAuthAPI {
  /// A software object that will interact with Firebase
  static final FirebaseAuth auth = FirebaseAuth.instance;

  /// Returns a stream of [User] objects representing the authentication state changes.
  ///
  /// This stream emits events whenever the user's sign-in state changes, such as signing in
  /// or signing out. This way, we can customize the sign in per user.
  Stream<User?> getUserStream() {
    return auth.authStateChanges();
  }

  /// Signs in a user using Google Sign-In.
  ///
  /// This method initiates the Google Sign-In flow, retrieves the user's credentials, and
  /// signs them into Firebase. If the user cancels the sign-in process, it returns a message
  /// indicating the cancellation. On success, it returns `null`. On failure, it returns an
  /// error message.
  ///
  /// Returns:
  /// - `null` if the sign-in is successful.
  /// - A string message if an error occurs or the user cancels the sign-in.
  Future<String?> signInWithGoogle() async {
    try {
      // Initialize a googleUser object and start the Google sign-in process.
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return "Sign in cancelled";
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Use token-based authentication for sign-in, which is something OAuth does.
      // This was also discussed in CMSC 100 - Web Programming
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await auth.signInWithCredential(credential);
      return null; // success
    } on FirebaseAuthException catch (e) {
      return "Firebase error: ${e.message}";
    } catch (e) {
      return "Sign in failed: ${e.toString()}";
    }
  }

  /// Signs in a user using email and password.
  ///
  /// This method attempts to sign in a user with the provided email and password. On success,
  /// it returns a success message. On failure, it returns an error message with the failure reason.
  ///
  /// Parameters:
  /// - [email]: The user's email address.
  /// - [password]: The user's password.
  ///
  /// Returns:
  /// - A success message if the sign-in is successful.
  /// - An error message if the sign-in fails.
  Future<String> signIn(String email, String password) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
      return "Signed in successfully";
    } on FirebaseAuthException catch (e) {
      return "Failed at error ${e.code}";
    }
  }

  /// Signs out the currently signed-in user.
  ///
  /// This method signs out the user from Firebase Authentication.
  Future<void> signOut() async {
    await auth.signOut();
  }

  /// Creates a new user account using email and password.
  ///
  /// This method attempts to create a new user account with the provided email and password.
  /// On success, it returns `null`. On failure, it returns an error message.
  ///
  /// Parameters:
  /// - [email]: The email address for the new account.
  /// - [password]: The password for the new account.
  ///
  /// Returns:
  /// - `null` if the account creation is successful.
  /// - A string message if an error occurs.
  Future<String?> signUp(String email, String password) async {
    try {
      await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // no error
    } on FirebaseAuthException catch (e) {
      return e.message; // return readable message
    } catch (e) {
      return "An unknown error occurred";
    }
  }
}
