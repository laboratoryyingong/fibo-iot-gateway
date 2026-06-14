db = db.getSiblingDB(process.env.MONGO_INITDB_DATABASE);
db.createUser({
  user: "parseuser",
  pwd: "6c2a9f5c8d8e4f66b8a1c2d3",
  roles: [{ role: "readWrite", db: "parse" }]
});
