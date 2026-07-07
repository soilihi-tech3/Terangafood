const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

const dbPath = path.join(__dirname, 'db.json');

function loadDB() {
  if (!fs.existsSync(dbPath)) {
    fs.writeFileSync(dbPath, JSON.stringify({
      users: {
        "moussa.diop@gmail.com": {
          name: "Moussa Diop",
          email: "moussa.diop@gmail.com",
          phone: "+221 77 123 45 67",
          avatarUrl: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&auto=format&fit=crop",
          password: "password123"
        }
      },
      orders: {},
      orderHistory: {
        "moussa.diop@gmail.com": [
          {
            id: "TF-498172",
            itemsSummary: "Thiéboudienne Penda Mbaye × 1, Bissap Royal Glacé × 2",
            total: 5500,
            date: "28 Juin 2026",
            status: "livree",
            rating: 4.5,
            paymentMethod: "wave",
            deliveryMethod: "moto",
            departure: "Restaurant Le Teranga, Plateau",
            destination: "Route de la Pointe des Almadies, Dakar"
          },
          {
            id: "TF-124098",
            itemsSummary: "Double Teranga Burger × 2, Pizza Teranga Spéciale × 1",
            total: 14000,
            date: "15 Juin 2026",
            status: "livree",
            rating: 5.0,
            paymentMethod: "cash",
            deliveryMethod: "voiture",
            departure: "Restaurant Le Teranga, Plateau",
            destination: "Avenue Cheikh Anta Diop, Dakar"
          }
        ]
      },
      notifications: {},
      favorites: {}
    }, null, 2));
  }
  return JSON.parse(fs.readFileSync(dbPath, 'utf8'));
}

function saveDB(data) {
  fs.writeFileSync(dbPath, JSON.stringify(data, null, 2));
}

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
    imageUrl: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&auto=format&fit=crop",
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

// Authentication
app.post('/api/auth/register', (req, res) => {
  const { name, email, phone, password } = req.body;
  const db = loadDB();
  const key = email.toLowerCase().trim();
  db.users[key] = {
    name,
    email,
    phone,
    avatarUrl: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&auto=format&fit=crop",
    password
  };
  saveDB(db);
  res.status(201).json(db.users[key]);
});

app.post('/api/auth/login', (req, res) => {
  const { email, password } = req.body;
  const db = loadDB();
  const key = email.toLowerCase().trim();
  if (db.users[key]) {
    res.json(db.users[key]);
  } else {
    // Auto-create dynamically if not found
    const generatedName = key.split('@')[0];
    const capitalizedName = generatedName[0].toUpperCase() + generatedName.slice(1);
    const newUser = {
      name: capitalizedName,
      email: key,
      phone: "+221 77 999 99 99",
      avatarUrl: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&auto=format&fit=crop",
      password: password || "password123"
    };
    db.users[key] = newUser;
    saveDB(db);
    res.json(newUser);
  }
});

app.put('/api/auth/update', (req, res) => {
  const { name, email, phone, avatarUrl } = req.body;
  const db = loadDB();
  const key = email.toLowerCase().trim();
  if (db.users[key]) {
    db.users[key].name = name || db.users[key].name;
    db.users[key].phone = phone || db.users[key].phone;
    if (avatarUrl) db.users[key].avatarUrl = avatarUrl;
    saveDB(db);
    res.json(db.users[key]);
  } else {
    res.status(404).json({ error: "User not found" });
  }
});

// Order History
app.get('/api/history/:email', (req, res) => {
  const email = req.params.email.toLowerCase().trim();
  const db = loadDB();
  res.json(db.orderHistory[email] || []);
});

app.post('/api/history', (req, res) => {
  const { email, order } = req.body;
  const key = email.toLowerCase().trim();
  const db = loadDB();
  if (!db.orderHistory[key]) db.orderHistory[key] = [];
  db.orderHistory[key].unshift(order);
  saveDB(db);
  res.status(201).json(order);
});

app.put('/api/history/rate', (req, res) => {
  const { email, id, rating, review } = req.body;
  const key = email.toLowerCase().trim();
  const db = loadDB();
  const list = db.orderHistory[key] || [];
  const idx = list.indexWhere ? list.indexWhere(o => o.id === id) : list.findIndex(o => o.id === id);
  if (idx >= 0) {
    list[idx].rating = rating;
    list[idx].review = review;
    saveDB(db);
    res.json(list[idx]);
  } else {
    res.status(404).json({ error: "Order not found" });
  }
});

// Notifications
app.get('/api/notifications/:email', (req, res) => {
  const email = req.params.email.toLowerCase().trim();
  const db = loadDB();
  res.json(db.notifications[email] || []);
});

app.post('/api/notifications', (req, res) => {
  const { email, title, body } = req.body;
  const key = email.toLowerCase().trim();
  const db = loadDB();
  if (!db.notifications[key]) db.notifications[key] = [];
  const newItem = {
    id: Date.now().toString(),
    title,
    body,
    timestamp: Date.now(),
    isRead: false
  };
  db.notifications[key].unshift(newItem);
  saveDB(db);
  res.status(201).json(newItem);
});

app.put('/api/notifications/read-all', (req, res) => {
  const { email } = req.body;
  const key = email.toLowerCase().trim();
  const db = loadDB();
  const list = db.notifications[key] || [];
  for (const n of list) {
    n.isRead = true;
  }
  saveDB(db);
  res.json(list);
});

app.delete('/api/notifications/:email', (req, res) => {
  const email = req.params.email.toLowerCase().trim();
  const db = loadDB();
  db.notifications[email] = [];
  saveDB(db);
  res.json({ success: true });
});

// Favorites
app.get('/api/favorites/:email', (req, res) => {
  const email = req.params.email.toLowerCase().trim();
  const db = loadDB();
  res.json(db.favorites[email] || []);
});

app.post('/api/favorites/toggle', (req, res) => {
  const { email, item } = req.body;
  const key = email.toLowerCase().trim();
  const db = loadDB();
  if (!db.favorites[key]) db.favorites[key] = [];
  
  const idx = db.favorites[key].findIndex(f => f.id === item.id);
  let isFav = false;
  if (idx >= 0) {
    db.favorites[key].splice(idx, 1);
  } else {
    db.favorites[key].push(item);
    isFav = true;
  }
  saveDB(db);
  res.json({ isFavorite: isFav, list: db.favorites[key] });
});

// Orders
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
    deliveryMethod,
    createdAt: Date.now(),
    status: "confirmée",
    driverLocation: { ...restaurantLocation },
    restaurantLocation: { ...restaurantLocation },
    destinationLocation: destCoords
  };

  const db = loadDB();
  db.orders[orderId] = newOrder;
  saveDB(db);
  res.status(201).json(newOrder);
});

app.get('/api/orders/:id', (req, res) => {
  const orderId = req.params.id;
  const db = loadDB();
  const order = db.orders[orderId];

  if (!order) {
    return res.status(404).json({ error: "Order not found" });
  }

  // Update order simulation based on time elapsed
  const elapsed = (Date.now() - order.createdAt) / 1000;

  if (elapsed < 10) {
    order.status = "confirmée";
    order.driverLocation = { ...order.restaurantLocation };
  } else if (elapsed < 25) {
    order.status = "en_preparation";
    order.driverLocation = { ...order.restaurantLocation };
  } else if (elapsed < 60) {
    order.status = "en_chemin";
    const fraction = (elapsed - 25) / 35;
    order.driverLocation = interpolate(order.restaurantLocation, order.destinationLocation, fraction);
  } else {
    order.status = "livree";
    order.driverLocation = { ...order.destinationLocation };
  }

  db.orders[orderId] = order;
  saveDB(db);
  res.json(order);
});

app.listen(PORT, () => {
  console.log(`Terangafood API listening on port ${PORT}`);
});
