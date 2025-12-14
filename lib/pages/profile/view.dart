import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models/common/image_type.dart';
import 'package:PiliPlus/pages/profile/controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfilePage extends GetView<ProfileController> {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Who's watching?"),
        centerTitle: true,
      ),
      body: Center(
        child: Obx(
          () => GridView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: controller.profiles.length,
            itemBuilder: (context, index) {
              final profile = controller.profiles[index];
              return GestureDetector(
                onTap: () => controller.switchAccount(profile.account),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: NetworkImgLayer(
                          src: profile.userInfo.face,
                          width: 100,
                          height: 100,
                          type: ImageType.avatar,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      profile.userInfo.uname ?? 'Guest',
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
