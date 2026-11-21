abstract final class StyleCatalog {
  static const specialCoats = {
    'coat.zebra',
    'coat.blue',
    'coat.green',
    'coat.redwhite',
    'coat.dalmatian',
    'coat.tiger',
  };
  static const specialPatterns = {'zebra', 'redwhite', 'greenwhite', 'dots'};
  static String? specialFamily(String id) {
    if (specialCoats.contains(id)) return 'coat';
    final model = clothingModels[id];
    if (model == null || !specialPatterns.contains(id.split('_').last)) {
      return null;
    }
    return model;
  }

  static const clothingModels = {
    "outfit.overalls_blue": "outfit.teal",
    "outfit.overalls_white": "outfit.teal",
    "outfit.overalls_black": "outfit.teal",
    "outfit.overalls_zebra": "outfit.teal",
    "outfit.overalls_redwhite": "outfit.teal",
    "outfit.overalls_greenwhite": "outfit.teal",
    "outfit.overalls_dots": "outfit.teal",
    "outfit.sweater_blue": "outfit.sweater_red",
    "outfit.sweater_white": "outfit.sweater_red",
    "outfit.sweater_black": "outfit.sweater_red",
    "outfit.sweater_zebra": "outfit.sweater_red",
    "outfit.sweater_redwhite": "outfit.sweater_red",
    "outfit.sweater_greenwhite": "outfit.sweater_red",
    "outfit.sweater_dots": "outfit.sweater_red",
    "outfit.raincoat_blue": "outfit.raincoat_blue",
    "outfit.raincoat_white": "outfit.raincoat_blue",
    "outfit.raincoat_black": "outfit.raincoat_blue",
    "outfit.raincoat_zebra": "outfit.raincoat_blue",
    "outfit.raincoat_redwhite": "outfit.raincoat_blue",
    "outfit.raincoat_greenwhite": "outfit.raincoat_blue",
    "outfit.raincoat_dots": "outfit.raincoat_blue",
    "outfit.dress_blue": "outfit.dress_pink",
    "outfit.dress_white": "outfit.dress_pink",
    "outfit.dress_black": "outfit.dress_pink",
    "outfit.dress_zebra": "outfit.dress_pink",
    "outfit.dress_redwhite": "outfit.dress_pink",
    "outfit.dress_greenwhite": "outfit.dress_pink",
    "outfit.dress_dots": "outfit.dress_pink",
  };
}
