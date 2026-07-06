const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Senegal Geolocations (Regions -> Neighborhoods -> Streets)
const locations = [
  {
    region: "Dakar",
    neighborhoods: [
      {
        name: "Almadies",
        streets: [
          { name: "Route de la Pointe des Almadies", lat: 14.7465, lng: -17.5258 },
          { name: "Rue des Mamelles", lat: 14.7238, lng: -17.5112 },
          { name: "Avenue du Plateau", lat: 14.7390, lng: -17.5190 }
        ]
      },
      {
        name: "Plateau",
        streets: [
          { name: "Avenue Léopold Sédar Senghor", lat: 14.6678, lng: -17.4344 },
          { name: "Rue Carnot", lat: 14.6712, lng: -17.4367 },
          { name: "Boulevard de la République", lat: 14.6645, lng: -17.4390 }
        ]
      },
      {
        name: "Médina",
        streets: [
          { name: "Avenue Blaise Diagne", lat: 14.6822, lng: -17.4485 },
          { name: "Rue 22", lat: 14.6845, lng: -17.4510 }
        ]
      },
      {
        name: "Fann / Mermoz",
        streets: [
          { name: "Avenue Cheikh Anta Diop", lat: 14.6890, lng: -17.4690 },
          { name: "Route de la Corniche Ouest", lat: 14.6925, lng: -17.4780 }
        ]
      }
    ]
  },
  {
    region: "Thiès",
    neighborhoods: [
      {
        name: "Randoulène",
        streets: [
          { name: "Avenue de Caen", lat: 14.7935, lng: -16.9242 },
          { name: "Rue Foch", lat: 14.7912, lng: -16.9210 }
        ]
      },
      {
        name: "Grand Standing",
        streets: [
          { name: "Route de Dakar", lat: 14.7820, lng: -16.9405 }
        ]
      }
    ]
  },
  {
    region: "Saint-Louis",
    neighborhoods: [
      {
        name: "Île de Saint-Louis",
        streets: [
          { name: "Rue Blaise Diagne", lat: 15.0255, lng: -16.5050 },
          { name: "Quai Henry Jay", lat: 15.0220, lng: -16.5042 }
        ]
      }
    ]
  }
];

// Restaurant Location (Dakar Center baseline)
const restaurantLocation = { lat: 14.6812, lng: -17.4435, name: "Teranga Food Central Kitchen" };

// Food Menu
const menu = [
  {
    id: "1",
    name: "Thiéboudienne Penda Mbaye",
    category: "Plats Sénégalais",
    description: "Le plat national emblématique du Sénégal. Riz cassé rouge cuit dans un bouillon de poisson savoureux, accompagné de poisson farci, manioc, carotte, chou et aubergine.",
    price: 3500,
    rating: 4.9,
    imageUrl: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&auto=format&fit=crop", // placeholder image but let's use good public URL
    ingredients: ["Riz cassé", "Poisson Dorade", "Légumes", "Piment", "Guedj (poisson séché)", "Yet"]
  },
  {
    id: "2",
    name: "Yassa au Poulet",
    category: "Plats Sénégalais",
    description: "Poulet mariné au citron, à la moutarde et à l'ail, braisé puis mijoté dans une généreuse sauce aux oignons caramélisés. Servi avec du riz blanc parfumé.",
    price: 3000,
    rating: 4.8,
    imageUrl: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500&auto=format&fit=crop",
    ingredients: ["Poulet fermier", "Oignons", "Citron vert", "Moutarde", "Olives", "Riz parfumé"]
  },
  {
    id: "3",
    name: "Mafé au Boeuf",
    category: "Plats Sénégalais",
    description: "Un ragoût onctueux originaire de l'Afrique de l'Ouest, composé de morceaux de bœuf mijotés dans une sauce riche à base de pâte d'arachide et de tomates.",
    price: 3200,
    rating: 4.7,
    imageUrl: "https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=500&auto=format&fit=crop",
    ingredients: ["Viande de bœuf", "Pâte d'arachide", "Pommes de terre", "Carottes", "Huile de palme"]
  },
  {
    id: "4",
    name: "Double Teranga Burger",
    category: "Burgers",
    description: "Double steak de bœuf grillé, fromage cheddar fondu, oignons caramélisés au yassa, laitue fraîche et sauce spéciale Teranga dans un pain brioché.",
    price: 4500,
    rating: 4.9,
    imageUrl: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500&auto=format&fit=crop",
    ingredients: ["Pain brioché", "Double Steak de Boeuf", "Cheddar", "Sauce Yassa", "Laitue", "Frites"]
  },
  {
    id: "5",
    name: "Pizza Teranga Spéciale",
    category: "Pizza",
    description: "Sauce tomate maison, mozzarella premium, lanières de poulet yassa, oignons doux, olives noires et un filet d'huile épicée.",
    price: 5000,
    rating: 4.6,
    imageUrl: "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500&auto=format&fit=crop",
    ingredients: ["Pâte à pizza fine", "Poulet grillé", "Oignons caramélisés", "Mozzarella", "Origan"]
  },
  {
    id: "6",
    name: "Thiakry Onctueux",
    category: "Desserts",
    description: "Le dessert traditionnel sénégalais à base de semoule de mil mélangée avec un yaourt sucré aromatisé à la fleur d'oranger et à la muscade.",
    price: 1500,
    rating: 4.9,
    imageUrl: "https://images.unsplash.com/photo-1488477181946-6428a0291777?w=500&auto=format&fit=crop",
    ingredients: ["Mil", "Yaourt concentré (sow)", "Sucre", "Vanille", "Fleur d'oranger", "Raisins secs"]
  },
  {
    id: "7",
    name: "Bissap Royal Glacé",
    category: "Boissons",
    description: "Boisson rafraîchissante traditionnelle sénégalaise préparée à partir d'infusion de fleurs d'hibiscus rouge séchées, aromatisée à la menthe fraîche.",
    price: 1000,
    rating: 4.9,
    imageUrl: "https://images.unsplash.com/photo-1497534446932-c925b458314e?w=500&auto=format&fit=crop",
    ingredients: ["Fleurs d'Hibiscus", "Sucre", "Menthe fraîche", "Arôme de fraise"]
  },
  {
    id: "8",
    name: "Jus de Bouye (Pain de Singe)",
    category: "Boissons",
    description: "Jus traditionnel épais et velouté à base de pulpe de fruit du baobab sauvage du Sénégal, mélangé avec un peu de lait concentré sucré.",
    price: 1200,
    rating: 4.8,
    imageUrl: "https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=500&auto=format&fit=crop",
    ingredients: ["Pain de singe (Baobab)", "Lait concentré", "Sucre vanillé", "Eau"]
  }
];

// Active Orders DB Simulation
const orders = {};

// Helper to interpolate coordinates
function interpolate(start, end, fraction) {
  return {
    lat: start.lat + (end.lat - start.lat) * fraction,
    lng: start.lng + (end.lng - start.lng) * fraction
  };
}

// Endpoints
app.get('/api/locations', (req, res) => {
  res.json({ locations, restaurantLocation });
});

app.get('/api/menu', (req, res) => {
  res.json(menu);
});

app.post('/api/orders', (req, res) => {
  const { items, address, deliveryMethod } = req.body;
  if (!items || !address || !deliveryMethod) {
    return res.status(400).json({ error: "Missing required order information (items, address, deliveryMethod)" });
  }

  const orderId = "TF-" + Math.floor(100000 + Math.random() * 900000);
  
  // Find destination coordinates from our locations DB
  let destCoords = { lat: 14.7238, lng: -17.5112 }; // Default Mamelles
  for (const reg of locations) {
    for (const neigh of reg.neighborhoods) {
      const match = neigh.streets.find(s => s.name === address);
      if (match) {
        destCoords = { lat: match.lat, lng: match.lng };
        break;
      }
    }
  }

  const newOrder = {
    id: orderId,
    items,
    address,
    deliveryMethod, // "moto" or "voiture"
    createdAt: Date.now(),
    status: "confirmée", // "confirmée", "en_preparation", "en_chemin", "livree"
    driverLocation: { ...restaurantLocation },
    restaurantLocation: { ...restaurantLocation },
    destinationLocation: destCoords
  };

  orders[orderId] = newOrder;
  res.status(201).json(newOrder);
});

app.get('/api/orders/:id', (req, res) => {
  const orderId = req.params.id;
  const order = orders[orderId];

  if (!order) {
    return res.status(404).json({ error: "Order not found" });
  }

  // Update order simulation based on time elapsed
  const elapsed = (Date.now() - order.createdAt) / 1000; // in seconds

  if (elapsed < 10) {
    order.status = "confirmée";
    order.driverLocation = { ...order.restaurantLocation };
  } else if (elapsed < 25) {
    order.status = "en_preparation";
    order.driverLocation = { ...order.restaurantLocation };
  } else if (elapsed < 60) {
    order.status = "en_chemin";
    // Interpolate path between restaurant and destination
    const fraction = (elapsed - 25) / 35; // 0.0 to 1.0
    order.driverLocation = interpolate(order.restaurantLocation, order.destinationLocation, fraction);
  } else {
    order.status = "livree";
    order.driverLocation = { ...order.destinationLocation };
  }

  res.json(order);
});

app.listen(PORT, () => {
  console.log(`Terangafood API listening on port ${PORT}`);
});
