"""
Store manager application
SPDX - License - Identifier: LGPL - 3.0 - or -later
Auteurs : Gabriel C. Ullmann, Fabio Petrillo, 2025
"""
from views.main_view import MainView

if __name__ == '__main__':
    print("===== LE MAGASIN DU COIN =====")
    main_menu = MainView()
    main_menu.show_main_menu()
