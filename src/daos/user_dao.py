"""
User DAO (Data Access Object)
SPDX - License - Identifier: LGPL - 3.0 - or -later
Auteurs : Gabriel C. Ullmann, Fabio Petrillo, 2025
"""
import os
from dotenv import load_dotenv
from pymongo import MongoClient
from models.user import User

class UserDAO:
    def __init__(self):
        try:
            # Try Docker path first, then local path
            env_path = ".env"
            if not os.path.exists(env_path):
                env_path = "../.env"
            print(os.path.abspath(env_path))
            load_dotenv(dotenv_path=env_path)
            
            mongo_host = os.getenv("MONGODB_HOST")
            db_user = os.getenv("DB_USERNAME")
            db_pass = os.getenv("DB_PASSWORD")
            
            # Connect to MongoDB
            if db_user and db_pass:
                connection_string = f"mongodb://{db_user}:{db_pass}@{mongo_host}:27017/"
                self.client = MongoClient(connection_string, authSource='admin')
            else:
                connection_string = f"mongodb://{mongo_host}:27017/"
                self.client = MongoClient(connection_string)
            self.db = self.client['mydb']  # Use same database name as MySQL
            self.collection = self.db['users']
            
        except FileNotFoundError as e:
            print("Attention : Veuillez créer un fichier .env")
        except Exception as e:
            print("Erreur MongoDB : " + str(e))

    def select_all(self):
        """ Select all users from MongoDB """
        users = []
        for doc in self.collection.find():
            # Convert MongoDB ObjectId to string for compatibility
            user_id = str(doc.get('_id', doc.get('id', None)))
            name = doc.get('name', '')
            email = doc.get('email', '')
            users.append(User(user_id, name, email))
        return users

    def insert(self, user):
        """ Insert given user into MongoDB """
        user_doc = {
            'name': user.name,
            'email': user.email
        }
        result = self.collection.insert_one(user_doc)
        return str(result.inserted_id)

    def update(self, user):
        """ Update given user in MongoDB """
        # Try to find by string ID first, then by ObjectId
        from bson import ObjectId
        try:
            # If user.id is a valid ObjectId string, convert it
            if len(user.id) == 24:  # ObjectId length
                query = {'_id': ObjectId(user.id)}
            else:
                query = {'_id': user.id}
        except:
            query = {'_id': user.id}
            
        update_doc = {
            '$set': {
                'name': user.name,
                'email': user.email
            }
        }
        self.collection.update_one(query, update_doc)

    def delete(self, user_id):
        """ Delete user from MongoDB with given user ID """
        from bson import ObjectId
        try:
            # If user_id is a valid ObjectId string, convert it
            if len(str(user_id)) == 24:  # ObjectId length
                query = {'_id': ObjectId(user_id)}
            else:
                query = {'_id': user_id}
        except:
            query = {'_id': user_id}
            
        self.collection.delete_one(query)

    def delete_all(self): #optional
        """ Empty users collection in MongoDB """
        self.collection.delete_many({})
        
    def close(self):
        """ Close MongoDB connection """
        if self.client:
            self.client.close()
