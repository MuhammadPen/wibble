import 'package:flutter/material.dart';
import 'package:wibble/components/ui/loading.dart';

class CustomButton extends StatefulWidget {
  final Widget? child;
  final String? text;
  final Function()? onPressed;
  final bool? disabled;
  final int? height;
  final int? width;
  final double? horizontalPadding;
  final double? verticalPadding;
  final double? fontSize;
  final double? borderRadius;
  final Color? fontColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? shadowColor;
  final Color? loadingColor;

  @override
  State<CustomButton> createState() => _CustomButtonState();

  const CustomButton({
    super.key,
    this.child,
    this.text,
    this.onPressed,
    this.disabled,
    this.height,
    this.width,
    this.horizontalPadding,
    this.verticalPadding,
    this.fontSize = 52,
    this.borderRadius = 16,
    this.fontColor = Colors.white,
    this.backgroundColor,
    this.borderColor = Colors.black,
    this.shadowColor,
    this.loadingColor = Colors.white,
  });
}

class _CustomButtonState extends State<CustomButton> {
  bool _isPressed = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.disabled == true ? null : onPressed,
      onTapDown: (details) {
        if (_isLoading || widget.disabled == true) return;
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (details) {
        if (_isLoading || widget.disabled == true) return;
        setState(() {
          _isPressed = false;
        });
      },
      onTapCancel: () {
        if (_isLoading || widget.disabled == true) return;
        setState(() {
          _isPressed = false;
        });
      },
      child: Container(
        transform: _isPressed
            ? Matrix4.translationValues(-3, 3, 0)
            : Matrix4.translationValues(0, 0, 0),
        width: widget.width?.toDouble(),
        height: widget.height?.toDouble() ?? 100,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          horizontal: widget.horizontalPadding ?? 0,
          vertical: widget.verticalPadding ?? 0,
        ),
        decoration: BoxDecoration(
          color: widget.disabled == true
              ? Colors.grey[400]
              : widget.backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 16),
          border: Border.all(
            color: widget.borderColor ?? Colors.black,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.shadowColor ?? Colors.black,
              offset: _isPressed ? Offset(0, 0) : Offset(-3, 3),
            ),
          ],
        ),

        child: _isLoading
            ? Loading(color: widget.loadingColor ?? Colors.white)
            : widget.child ??
                  Text(
                    style: TextStyle(
                      fontFamily: "Baloo",
                      fontSize: widget.fontSize,
                      color: widget.fontColor,
                      height: 1.2,
                      decoration: TextDecoration.none,
                    ),
                    textAlign: TextAlign.center,
                    widget.text ?? "",
                  ),
      ),
    );
  }

  void onPressed() async {
    if (_isLoading || widget.disabled == true) return;

    setState(() {
      _isLoading = true;
    });

    await widget.onPressed?.call();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
