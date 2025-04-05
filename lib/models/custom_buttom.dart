import 'package:flutter/material.dart';
class CustomTextWidget extends StatelessWidget {
  final String txt;
  final double txtsize;
  final Color txtColor;
  final TextAlign txtAlign;
  final int maxLine;

  const CustomTextWidget({
    super.key,
    required this.txt,
    required this.txtsize,
    required this.txtColor,
    required this.txtAlign,
    this.maxLine = 2,
    TextOverflow overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      txt,
      textAlign: txtAlign,
      style: TextStyle(
        fontSize: txtsize,
        fontFamily: "Lato",
        fontWeight: FontWeight.bold,
        color: txtColor,
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onPress;
  final Color backgroundColor;
  final Color textColor;




  const CustomButton({
    super.key,
    required this.onPress,
    this.text = 'Write text',
    this.color = Colors.blue, required this.backgroundColor, required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center( // ✅ جعل الزر في منتصف الشاشة
      child: SizedBox(
        width: double.infinity, // ✅ جعل العرض بعرض الشاشة بالكامل
        height: 50, // ✅ تكبير الارتفاع
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50.0),
            ),
          ),
          onPressed: onPress,
          child: CustomTextWidget(
            txt: text,
            txtsize: 18, // ✅ تكبير حجم النص داخل الزر
            txtColor: Colors.black,
            txtAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}