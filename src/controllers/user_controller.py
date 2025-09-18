"""
User controller
SPDX - License - Identifier: LGPL - 3.0 - or -later
Auteurs : Gabriel C. Ullmann, Fabio Petrillo, 2025
"""

from daos.user_dao import UserDAO

class UserController:
    def __init__(self):
        self.dao = UserDAO()

    def list_users(self):
        """ List all users """
        return self.dao.select_all()
        
    def create_user(self, user):
        """ Create a new user based on user inputs """
        self.dao.insert(user)

    def update_user(self, user):
        """ Update an existing user """
        self.dao.update(user)

    def delete_user(self, user_id):
        """ Delete a user by ID """
        self.dao.delete(user_id)

    def shutdown(self):
        """ Close database connection """
        self.dao.close()
