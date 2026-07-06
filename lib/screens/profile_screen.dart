import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../services/api_service.dart';
import '../services/category_service.dart';
import '../models/food_model.dart';
import 'auth_screens.dart';
import 'favorites_screen.dart';
import '../services/order_history_service.dart';

class ProfileScreen extends StatefulWidget {
  final Map<FoodItem, int> cart;
  final Function(FoodItem, int) onUpdateCart;

  const ProfileScreen({
    super.key,
    required this.cart,
    required this.onUpdateCart,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  final List<String> _avatarPresets = [
    "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop",
    "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&auto=format&fit=crop",
    "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&auto=format&fit=crop",
    "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&auto=format&fit=crop",
    "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200&auto=format&fit=crop",
    "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&auto=format&fit=crop",
  ];

  final List<Map<String, String>> _addresses = [
    {"label": "Domicile", "street": "Rue des Mamelles, Dakar"},
    {"label": "Bureau", "street": "Avenue Cheikh Anta Diop, Dakar"},
  ];

  void _showAvatarPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Choisir une photo de profil",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _avatarPresets.length,
                  itemBuilder: (_, i) {
                    final url = _avatarPresets[i];
                    final isSelected = _authService.avatarUrl == url;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _authService.avatarUrl = url);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Photo de profil mise à jour !"),
                            backgroundColor: const Color(0xFFE8612C),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFE8612C)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(url),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                "Ou coller le lien d'une photo (URL)",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: "https://exemple.com/ma-photo.jpg",
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          setState(() => _authService.avatarUrl = val.trim());
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Photo de profil mise à jour via URL !"),
                              backgroundColor: const Color(0xFFE8612C),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }

  void _logout() {
    _authService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _showShareAppSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Partager TerangaFood via",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildShareOption(
                    "WhatsApp",
                    Icons.chat_bubble_rounded,
                    const Color(0xFF25D366),
                    () => _triggerShare("WhatsApp"),
                  ),
                  _buildShareOption(
                    "Instagram",
                    Icons.camera_alt_rounded,
                    const Color(0xFFE1306C),
                    () => _triggerShare("Instagram"),
                  ),
                  _buildShareOption(
                    "Snapchat",
                    Icons.snapchat_rounded,
                    const Color(0xFFFFFC00),
                    () => _triggerShare("Snapchat"),
                    textColor: Colors.black87,
                  ),
                  _buildShareOption(
                    "Facebook",
                    Icons.facebook_rounded,
                    const Color(0xFF1877F2),
                    () => _triggerShare("Facebook"),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareOption(String label, IconData icon, Color color, VoidCallback onTap, {Color textColor = Colors.white}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(icon, color: textColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade300 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _triggerShare(String platform) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✓ Lien de l'application TerangaFood partagé avec succès sur $platform !"),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: Text(
            "Changer de mot de passe",
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPasswordCtrl,
                obscureText: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: const InputDecoration(
                  labelText: "Ancien mot de passe",
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordCtrl,
                obscureText: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: const InputDecoration(
                  labelText: "Nouveau mot de passe",
                  prefixIcon: Icon(Icons.vpn_key_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordCtrl,
                obscureText: true,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: const InputDecoration(
                  labelText: "Confirmer le mot de passe",
                  prefixIcon: Icon(Icons.check_circle_outline_rounded),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () {
                if (oldPasswordCtrl.text != _authService.password) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("❌ L'ancien mot de passe est incorrect !"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (newPasswordCtrl.text.isEmpty || newPasswordCtrl.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("❌ Le nouveau mot de passe doit faire au moins 6 caractères !"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (newPasswordCtrl.text != confirmPasswordCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("❌ Les deux mots de passe ne correspondent pas !"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                setState(() {
                  _authService.password = newPasswordCtrl.text;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✅ Mot de passe modifié avec succès !"),
                    backgroundColor: Color(0xFFE8612C),
                  ),
                );
              },
              child: const Text(
                "Confirmer",
                style: TextStyle(
                  color: Color(0xFFE8612C),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _editField(String title, String current, Function(String) onSave) {
    final ctrl = TextEditingController(text: current);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text("Modifier $title",
            style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: TextField(
          controller: ctrl,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
              hintText: "Nouveau $title",
              hintStyle: TextStyle(color: Colors.grey.shade500)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annuler")),
          TextButton(
            onPressed: () {
              if (ctrl.text.isNotEmpty) {
                onSave(ctrl.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text("Enregistrer",
                style: TextStyle(color: Color(0xFFE8612C))),
          ),
        ],
      ),
    );
  }

  void _addNewAddress() {
    final labelCtrl = TextEditingController();
    final streetCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ApiService apiService = ApiService();

    List<Map<String, dynamic>> suggestions = [];
    bool searching = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              title: Text("Ajouter une adresse",
                  style: TextStyle(color: isDark ? Colors.white : Colors.black)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: labelCtrl,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: const InputDecoration(hintText: "Libellé (ex: Bureau)"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: streetCtrl,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: "Rechercher la rue (ex: Almadies)",
                      suffixIcon: searching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE8612C)),
                              ),
                            )
                          : null,
                    ),
                    onChanged: (val) async {
                      if (val.trim().length > 2) {
                        setDialogState(() => searching = true);
                        final res = await apiService.searchAddress(val.trim());
                        if (!dialogCtx.mounted) return;
                        setDialogState(() {
                          suggestions = res;
                          searching = false;
                        });
                      } else {
                        if (!dialogCtx.mounted) return;
                        setDialogState(() {
                          suggestions = [];
                          searching = false;
                        });
                      }
                    },
                  ),
                  if (suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      height: 120,
                      width: 280,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: suggestions.length,
                        itemBuilder: (c, idx) {
                          final item = suggestions[idx];
                          final displayName = item['display_name'] as String;
                          return ListTile(
                            title: Text(
                              displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            dense: true,
                            onTap: () {
                              setDialogState(() {
                                streetCtrl.text = displayName;
                                suggestions = [];
                              });
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Annuler")),
                TextButton(
                  onPressed: () {
                    if (labelCtrl.text.isNotEmpty && streetCtrl.text.isNotEmpty) {
                      setState(() => _addresses.add(
                          {"label": labelCtrl.text, "street": streetCtrl.text}));
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text("Ajouter",
                      style: TextStyle(color: Color(0xFFE8612C))),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Mon Profil 👤",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Profile Header ────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: _showAvatarPicker,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFE8612C),
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 52,
                              backgroundImage:
                                  NetworkImage(_authService.avatarUrl),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 4,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8612C),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _authService.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8612C).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Rôle: Administrateur (Privilèges activés)",
                        style: TextStyle(
                          color: Color(0xFFE8612C),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _authService.email,
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _authService.phone,
                      style: TextStyle(
                        color: const Color(0xFFE8612C),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatChip("${OrderHistoryService().all.length}", "Commandes", Icons.receipt_long_rounded),
                        _buildStatChip(
                            OrderHistoryService().all.where((o) => o.rating != null).isEmpty
                                ? "5.0"
                                : (OrderHistoryService().all.where((o) => o.rating != null).fold<double>(0.0, (sum, o) => sum + o.rating!) /
                                        OrderHistoryService().all.where((o) => o.rating != null).length)
                                    .toStringAsFixed(1),
                            "Ma note",
                            Icons.star_rounded),
                        _buildStatChip(
                            "${OrderHistoryService().all.length * 500}", "Points gagnés", Icons.emoji_events_rounded),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Settings Section ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informations personnelles
                  _sectionTitle("Informations personnelles", isDark),
                  const SizedBox(height: 10),
                  _buildInfoItem(
                    Icons.person_rounded,
                    "Nom complet",
                    _authService.name,
                    isDark,
                    () => _editField("Nom complet", _authService.name,
                        (v) => setState(() => _authService.name = v)),
                  ),
                  _buildInfoItem(
                    Icons.phone_rounded,
                    "Téléphone",
                    _authService.phone,
                    isDark,
                    () => _editField("Téléphone", _authService.phone,
                        (v) => setState(() => _authService.phone = v)),
                  ),
                  _buildInfoItem(
                    Icons.email_rounded,
                    "Email",
                    _authService.email,
                    isDark,
                    () => _editField("Email", _authService.email,
                        (v) => setState(() => _authService.email = v)),
                  ),

                  const SizedBox(height: 28),

                  // Adresses
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionTitle("Mes adresses", isDark),
                      TextButton.icon(
                        onPressed: _addNewAddress,
                        icon: const Icon(Icons.add_rounded,
                            size: 16, color: Color(0xFFE8612C)),
                        label: const Text("Ajouter",
                            style: TextStyle(
                                color: Color(0xFFE8612C),
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._addresses.asMap().entries.map((e) {
                    final i = e.key;
                    final addr = e.value;
                    return _buildAddressCard(addr, i, isDark);
                  }),

                  const SizedBox(height: 28),

                  // Préférences
                  _sectionTitle("Préférences", isDark),
                  const SizedBox(height: 10),

                  // Theme toggle
                  _buildSettingsTile(
                    icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    iconColor: isDark ? Colors.indigo : Colors.amber,
                    title: "Thème de l'application",
                    subtitle: isDark ? "Mode sombre activé" : "Mode clair activé",
                    isDark: isDark,
                    trailing: Switch(
                      value: isDark,
                      onChanged: (_) {
                        ThemeService.toggleTheme();
                      },
                      activeColor: const Color(0xFFE8612C),
                      trackColor: MaterialStateProperty.resolveWith((states) {
                        if (states.contains(MaterialState.selected)) {
                          return const Color(0xFFE8612C).withOpacity(0.3);
                        }
                        return Colors.grey.shade300;
                      }),
                    ),
                  ),

                  _buildSettingsTile(
                    icon: Icons.notifications_rounded,
                    iconColor: Colors.blue,
                    title: "Notifications",
                    subtitle: "Recevoir les alertes de livraison",
                    isDark: isDark,
                    trailing: Switch(
                      value: true,
                      onChanged: (_) {},
                      activeColor: const Color(0xFFE8612C),
                    ),
                  ),

                  GestureDetector(
                    onTap: _showChangePasswordDialog,
                    child: _buildSettingsTile(
                      icon: Icons.lock_reset_rounded,
                      iconColor: Colors.purple,
                      title: "Sécurité",
                      subtitle: "Changer de mot de passe",
                      isDark: isDark,
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: Colors.grey.shade400),
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FavoritesScreen(
                            cart: widget.cart,
                            onUpdateCart: widget.onUpdateCart,
                          ),
                        ),
                      ).then((_) => setState(() {}));
                    },
                    child: _buildSettingsTile(
                      icon: Icons.favorite_rounded,
                      iconColor: Colors.redAccent,
                      title: "Mes Favoris",
                      subtitle: "Voir mes plats sauvegardés",
                      isDark: isDark,
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: Colors.grey.shade400),
                    ),
                  ),

                  GestureDetector(
                    onTap: _showShareAppSheet,
                    child: _buildSettingsTile(
                      icon: Icons.share_rounded,
                      iconColor: Colors.blueAccent,
                      title: "Partager l'application",
                      subtitle: "Partager via WhatsApp, Instagram, Snapchat...",
                      isDark: isDark,
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: Colors.grey.shade400),
                    ),
                  ),

                  // Admin Actions
                  _sectionTitle("Administration", isDark),
                  const SizedBox(height: 10),

                  GestureDetector(
                    onTap: _showAddProductDialog,
                    child: _buildSettingsTile(
                      icon: Icons.add_business_rounded,
                      iconColor: const Color(0xFFE8612C),
                      title: "Ajouter un produit / catégorie",
                      subtitle: "Créer des plats ou des catégories",
                      isDark: isDark,
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: Colors.grey.shade400),
                    ),
                  ),

                  GestureDetector(
                    onTap: _showManageCategoriesDialog,
                    child: _buildSettingsTile(
                      icon: Icons.category_rounded,
                      iconColor: const Color(0xFFE8612C),
                      title: "Gérer les catégories",
                      subtitle: "Modifier ou supprimer les catégories",
                      isDark: isDark,
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: Colors.grey.shade400),
                    ),
                  ),

                  GestureDetector(
                    onTap: _showManageProductsDialog,
                    child: _buildSettingsTile(
                      icon: Icons.fastfood_rounded,
                      iconColor: const Color(0xFFE8612C),
                      title: "Gérer les produits",
                      subtitle: "Modifier ou supprimer les plats",
                      isDark: isDark,
                      trailing: Icon(Icons.chevron_right_rounded,
                          color: Colors.grey.shade400),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded, color: Colors.red),
                      label: const Text(
                        "Se déconnecter",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFEBEE),
                        surfaceTintColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(color: Color(0xFFFFCDD2)),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      "TerangaFood v1.0.0",
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildStatChip(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFE8612C), size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFFE8612C)),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value,
    bool isDark,
    VoidCallback onTap,
  ) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8612C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFE8612C), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.edit_rounded,
                  size: 16,
                  color: isDark ? Colors.white54 : Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(
      Map<String, String> addr, int index, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8612C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_on_rounded,
                color: Color(0xFFE8612C), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(addr["label"]!,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 2),
                Text(addr["street"]!,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _addresses.removeAt(index)),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  size: 16, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required Widget trailing,
  }) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFE8612C);
    
    // Add product form states
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final imgUrl1Ctrl = TextEditingController();
    final imgUrl2Ctrl = TextEditingController();
    final ingredientsCtrl = TextEditingController();
    
    // Add category state
    final newCatCtrl = TextEditingController();

    // Fetch from CategoryService
    final List<String> availableCategories = CategoryService()
        .categoryNames
        .where((name) => name != "Tous")
        .toList();

    String selectedCategory = availableCategories.isNotEmpty 
        ? availableCategories.first 
        : "Plats Sénégalais";
    double productRating = 5.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return DefaultTabController(
            length: 2,
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 10,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  TabBar(
                    indicatorColor: primaryColor,
                    labelColor: primaryColor,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: "Ajouter Produit"),
                      Tab(text: "Nouvelle Catégorie"),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 420,
                    child: TabBarView(
                      children: [
                        // Tab 1: Add Product Form
                        SingleChildScrollView(
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              // Category dropdown selector
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: selectedCategory,
                                      dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                      decoration: InputDecoration(
                                        labelText: "Catégorie",
                                        labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.black87),
                                      ),
                                      items: availableCategories.map((c) {
                                        return DropdownMenuItem(
                                          value: c,
                                          child: Text(c, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setModalState(() {
                                            selectedCategory = val;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: nameCtrl,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                decoration: const InputDecoration(labelText: "Nom du produit"),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: priceCtrl,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                      decoration: const InputDecoration(labelText: "Prix (FCFA)"),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  // Star rating selector slider
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Note: ${productRating.toStringAsFixed(1)}", style: const TextStyle(fontSize: 12)),
                                      Slider(
                                        value: productRating,
                                        min: 1.0,
                                        max: 5.0,
                                        divisions: 8,
                                        activeColor: primaryColor,
                                        onChanged: (v) {
                                          setModalState(() {
                                            productRating = v;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: imgUrl1Ctrl,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                decoration: const InputDecoration(labelText: "URL Photo Principale"),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: imgUrl2Ctrl,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                decoration: const InputDecoration(labelText: "URL Photo Galerie (Secondaire)"),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: descCtrl,
                                maxLines: 2,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                decoration: const InputDecoration(labelText: "Description / Ingrédients clés"),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: ingredientsCtrl,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                decoration: const InputDecoration(labelText: "Ingrédients séparés par virgule (ex: Riz, Poisson, Citron)"),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                                      final price = double.tryParse(priceCtrl.text) ?? 1000.0;
                                      final parsedIngredients = ingredientsCtrl.text.isNotEmpty
                                          ? ingredientsCtrl.text.split(",").map((e) => e.trim()).toList()
                                          : ["Ingrédients frais"];
                                      final defaultImg = imgUrl1Ctrl.text.isNotEmpty
                                          ? imgUrl1Ctrl.text
                                          : "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&auto=format&fit=crop";

                                      final item = FoodItem(
                                        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                                        name: nameCtrl.text.trim(),
                                        category: selectedCategory,
                                        description: descCtrl.text.trim(),
                                        price: price,
                                        rating: productRating,
                                        imageUrl: defaultImg,
                                        ingredients: parsedIngredients,
                                      );

                                      // Insert dynamically into local storage ApiService list
                                      ApiService.customMenuItems.add(item);

                                      Navigator.pop(modalCtx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("✓ Produit '${item.name}' ajouté avec succès !"),
                                          backgroundColor: primaryColor,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: const Text("Créer le produit", style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Tab 2: Add Category Form
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              const Text(
                                "Créer une nouvelle catégorie personnalisée",
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: newCatCtrl,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                decoration: const InputDecoration(
                                  labelText: "Nom de la catégorie (ex: Salades)",
                                ),
                              ),
                              const SizedBox(height: 30),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (newCatCtrl.text.isNotEmpty) {
                                      final catName = newCatCtrl.text.trim();
                                      if (!availableCategories.contains(catName)) {
                                        // Save to dynamic singleton CategoryService
                                        CategoryService().addCategory(catName, Icons.restaurant_menu_rounded);
                                        setModalState(() {
                                          availableCategories.add(catName);
                                          selectedCategory = catName;
                                        });
                                        newCatCtrl.clear();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("✓ Catégorie '$catName' ajoutée ! Vous pouvez créer des produits dedans."),
                                            backgroundColor: primaryColor,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: const Text("Créer la catégorie", style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
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
          );
        });
      },
    );
  }

  void _showManageCategoriesDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFE8612C);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocalState) {
          final categories = CategoryService().categories;
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Gérer les catégories",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final name = cat["name"] as String;
                      final isSystem = ["Tous", "Plats Sénégalais", "Burgers", "Pizza", "Boissons", "Desserts"].contains(name);

                      return ListTile(
                        leading: Icon(cat["icon"] as IconData, color: primaryColor),
                        title: Text(
                          name,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        ),
                        trailing: isSystem
                            ? Text("Système", style: TextStyle(color: Colors.grey.shade500, fontSize: 11))
                            : IconButton(
                                icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                                onPressed: () {
                                  CategoryService().deleteCategory(name);
                                  setLocalState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("✓ Catégorie '$name' supprimée !"),
                                      backgroundColor: primaryColor,
                                    ),
                                  );
                                },
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showManageProductsDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFE8612C);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setLocalState) {
          return FutureBuilder<List<FoodItem>>(
            future: ApiService().getMenu(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ));
              }

              final products = snapshot.data!;
              return Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Gérer les plats",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 350),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = products[index];
                          final isCustom = item.id.startsWith("custom_");

                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.imageUrl,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 44,
                                  height: 44,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.fastfood_rounded, size: 18),
                                ),
                              ),
                            ),
                            title: Text(
                              item.name,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              "${item.price.toStringAsFixed(0)} FCFA · ${item.category}",
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isCustom)
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _showEditProductDialog(item);
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                                  onPressed: () {
                                    if (isCustom) {
                                      ApiService.customMenuItems.removeWhere((p) => p.id == item.id);
                                    } else {
                                      ApiService.fallbackMenu.removeWhere((p) => p.id == item.id);
                                    }
                                    setLocalState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("✓ Plat '${item.name}' supprimé !"),
                                        backgroundColor: primaryColor,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }
          );
        });
      },
    );
  }

  void _showEditProductDialog(FoodItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFE8612C);

    final nameCtrl = TextEditingController(text: item.name);
    final priceCtrl = TextEditingController(text: item.price.toStringAsFixed(0));
    final descCtrl = TextEditingController(text: item.description);
    final imgUrl1Ctrl = TextEditingController(text: item.imageUrl);
    final ingredientsCtrl = TextEditingController(text: item.ingredients.join(", "));

    final List<String> availableCategories = CategoryService()
        .categoryNames
        .where((name) => name != "Tous")
        .toList();

    String selectedCategory = availableCategories.contains(item.category)
        ? item.category
        : availableCategories.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                "Modifier le produit",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                decoration: const InputDecoration(labelText: "Catégorie"),
                items: availableCategories.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(c, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) selectedCategory = val;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: const InputDecoration(labelText: "Nom du produit"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: const InputDecoration(labelText: "Prix (FCFA)"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: imgUrl1Ctrl,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: const InputDecoration(labelText: "URL Photo"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ingredientsCtrl,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: const InputDecoration(labelText: "Ingrédients (virgules)"),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                      setState(() {
                        item.name = nameCtrl.text.trim();
                        item.price = double.tryParse(priceCtrl.text) ?? item.price;
                        item.imageUrl = imgUrl1Ctrl.text.trim();
                        item.description = descCtrl.text.trim();
                        item.category = selectedCategory;
                        item.ingredients = ingredientsCtrl.text.split(",").map((e) => e.trim()).toList();
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("✓ Produit '${item.name}' mis à jour !"),
                          backgroundColor: primaryColor,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Enregistrer les modifications", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
