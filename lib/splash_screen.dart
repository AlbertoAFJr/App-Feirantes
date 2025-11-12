import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeInController;
  late final AnimationController _fadeOutController;
  late final Animation<double> _fadeInAnimation;
  late final Animation<double> _fadeOutAnimation;

  @override
  void initState() {
    super.initState();

    // 🔹 Esconde as barras do sistema (tela cheia)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // 🔹 Animações de entrada e saída
    _fadeInController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _fadeInAnimation =
        CurvedAnimation(parent: _fadeInController, curve: Curves.easeIn);
    _fadeInController.forward();

    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeOutAnimation =
        CurvedAnimation(parent: _fadeOutController, curve: Curves.easeOut);

    // 🔹 Exibe o splash por 3 segundos antes de transição
    Timer(const Duration(seconds: 3), () async {
      await _fadeOutController.forward();
      if (mounted) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade700, // Fundo verde para bordas
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: FadeTransition(
          opacity: ReverseAnimation(_fadeOutAnimation),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 🖼️ Mostra 100% da imagem (sem cortes)
              Center(
                child: Image.asset(
                  'assets/icon/icon2.png',
                  fit: BoxFit.contain, // <--- Mostra toda a imagem
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                ),
              ),

              // 🔄 Loader e texto central
              Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                    SizedBox(height: 18),
                    Text(
                      'Desenvolvido por AlbertoAFJr',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
