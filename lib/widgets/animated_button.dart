import 'package:flutter/material.dart';

class AnimatedButton extends StatelessWidget {
  final String? label;
  final AnimationController controller;
  final Animation<double> largura;
  final Animation<double> altura;
  final Animation<double> radius;
  final Animation<double> opacidade;

  AnimatedButton({super.key, required this.controller, this.label})
      : largura = Tween<double>(
          begin: 0,
          end: 500,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.0, 0.5),
          ),
        ),
        altura = Tween<double>(
          begin: 0,
          end: 50,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.5, 0.7),
          ),
        ),
        radius = Tween<double>(
          begin: 10,
          end: 20,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.6, 1.0),
          ),
        ),
        opacidade = Tween<double>(
          begin: 0,
          end: 1,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.6, 0.8),
          ),
        );

  Widget _buildAnimation(BuildContext context, Widget? widget) {
    return SizedBox(
      width: largura.value,
      height: altura.value,
      child: Material(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(radius.value),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {},
          child: Center(
            child: FadeTransition(
              opacity: opacidade,
              child: Text(
                label ?? 'Button',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: _buildAnimation,
    );
  }
}
