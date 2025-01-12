import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:lage/components/homepage.dart';
import 'package:lage/components/tabpages/home_tab.dart';
import 'package:path/path.dart' as Path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/app_colors.dart';


class ProfileSettingScreen extends StatefulWidget {
  const ProfileSettingScreen({super.key});

  @override
  State<ProfileSettingScreen> createState() => _ProfileSettingScreenState();
}

class _ProfileSettingScreenState extends State<ProfileSettingScreen> {

  TextEditingController nameController = TextEditingController();
  TextEditingController homeController = TextEditingController();
  TextEditingController businessController = TextEditingController();
  TextEditingController shopController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  getImage(ImageSource source)async{
    final XFile? image = await _picker.pickImage(source: source);
    if(image!= null){
      selectedImage = File(image.path);
      setState(() {

      });
    }
  }

  uploadImage(File image)async{

    String imageUrl = '';
    String fileName = Path.basename(image.path);
    var reference = FirebaseStorage.instance
        .ref()
        .child('users/$fileName');
    UploadTask uploadTask = reference.putFile(image);
    TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
    await taskSnapshot.ref.getDownloadURL().then(
          (value){
        imageUrl = value;
        print("Download URL: $value");
      },
    );
    return imageUrl;
  }

  storeUserInfo()async{
    String url = await uploadImage(selectedImage!);
    String uid = FirebaseAuth.instance.currentUser!.uid;

    FirebaseFirestore.instance.collection('users').doc(uid).set({
      'image': url,
      'name': nameController.text,
      'home_address': homeController.text,
      'business_address': businessController.text,
      'shopping_address' : shopController.text
    }).then((value){
      nameController.clear();
      homeController.clear();
      businessController.clear();
      shopController.clear();
      setState(() {
        isLoading = false;
      });
      Get.to(()=> HomeTabPage());
    });
  }

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              SizedBox(
                height: Get.height * 0.4,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: InkWell(
                        onTap: (){
                          getImage(ImageSource.camera);
                        },
                        child: selectedImage == null? Container(
                          width: 120,
                          height: 120,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xffD6D6D6)),
                          child: const Center(child: Icon(Icons.camera_alt_outlined,size: 40,color: Colors.white,),),
                        ):
                        Container(
                          width: 120,
                          height: 120,
                          margin:  EdgeInsets.only(bottom: 20),
                          decoration:  BoxDecoration(
                              image: DecorationImage(
                                  image: FileImage(selectedImage!),
                                  fit: BoxFit.fill),
                              shape: BoxShape.circle,
                              color: Color(0xffD6D6D6)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),



              const SizedBox(
                height: 20,
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 23),
                child: Column(
                  children: [
                    TextFieldWidget('Name', Icons.person_outlined, nameController),
                    const SizedBox(
                      height: 10,
                    ),
                    TextFieldWidget(
                        'Home Address', Icons.home_outlined, homeController),
                    const SizedBox(
                      height: 10,
                    ),
                    TextFieldWidget('Business Address', Icons.card_travel, businessController),
                    const SizedBox(
                      height: 10,
                    ),
                    TextFieldWidget('Shopping Center',
                        Icons.shopping_cart_outlined, shopController),
                    const SizedBox(
                      height: 30,
                    ),

                    isLoading? Center(child: CircularProgressIndicator(),) :greenButton('Submit', (){
                      setState(() {
                        isLoading = true;
                      });
                      storeUserInfo();
                    }),

                  ],
                ),
              ),
            ]
        ),
      ),
    );
  }

  TextFieldWidget(String title, IconData iconData, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xffA7A7A7)),),
        const SizedBox(
          height: 6,
        ),
        Container(
          width: Get.width,
          height: 50,
          decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 1
                )
              ],
              borderRadius: BorderRadius.circular(8)),
          child: TextField(
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xffA7A7A7)),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Icon(iconData, color: AppColors.greenColor,),
              ),
              border: InputBorder.none,
            ),
          ),
        )
      ],
    );
  }

  Widget greenButton(String title, Function onPressed) {
    return MaterialButton(
      minWidth: Get.width,
      height: 50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      color: AppColors.greenColor,
      onPressed: () => onPressed(),
      child: Text(
        title,
        style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}
