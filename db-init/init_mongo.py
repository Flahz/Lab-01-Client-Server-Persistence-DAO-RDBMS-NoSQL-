"""
Script d'initialisation MongoDB
SPDX - License - Identifier: LGPL - 3.0 - or -later
"""

import pymongo
import time

def init_mongodb():
    # Attendre que MongoDB soit prêt
    max_retries = 30
    for i in range(max_retries):
        try:
            # Connexion à MongoDB
            client = pymongo.MongoClient('mongodb://user:pass@mongo:27017/')
            db = client['mydb']  # Utiliser la même base de données que l'application
            
            # Vérifier si la collection users existe déjà et contient des données
            if db.users.count_documents({}) > 0:
                print("MongoDB déjà initialisé, aucune action nécessaire.")
                return
            
            # Insérer les utilisateurs de test
            users = [
                {
                    'name': 'Ada Lovelace',
                    'email': 'alovelace@example.com'
                },
                {
                    'name': 'Adele Goldberg', 
                    'email': 'agoldberg@example.com'
                },
                {
                    'name': 'Alan Turing',
                    'email': 'aturing@example.com'
                }
            ]
            
            result = db.users.insert_many(users)
            print(f"MongoDB initialisé avec succès! {len(result.inserted_ids)} utilisateurs ajoutés.")
            
            client.close()
            return
            
        except Exception as e:
            print(f"Tentative {i+1}/{max_retries}: En attente de MongoDB... ({e})")
            time.sleep(2)
    
    print("Erreur: Impossible de se connecter à MongoDB après plusieurs tentatives.")

if __name__ == "__main__":
    init_mongodb()
