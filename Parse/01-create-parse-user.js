db = db.getSiblingDB(process.env.PARSE_DATABASE_NAME || "parse");

db.createUser({
  user: process.env.MONGO_PARSE_USER,
  pwd: process.env.MONGO_PARSE_PASS,
  roles: [{ role: "readWrite", db: db.getName() }],
});
