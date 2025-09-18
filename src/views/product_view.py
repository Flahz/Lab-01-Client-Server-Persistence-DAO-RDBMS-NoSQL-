"""
Product view
SPDX - License - Identifier: LGPL - 3.0 - or -later
Auteurs : Gabriel C. Ullmann, Fabio Petrillo, 2025
"""
from models.product import Product
from controllers.product_controller import ProductController

class ProductView:
    @staticmethod
    def show_options():
        """ Show menu with operation options which can be selected by the user """
        controller = ProductController()
        while True:
            print("\n1. Montrer la liste d'items")
            print("2. Ajouter un item")
            print("3. Supprimer un item")
            print("4. Retour au menu principal")
            choice = input("Choisissez une option: ")

            if choice == '1':
                products = controller.list_products()
                ProductView.show_products(products)
            elif choice == '2':
                name, brand, price = ProductView.get_inputs()
                product = Product(None, name, brand, price)
                controller.create_product(product)
                print("Produit ajouté avec succès!")
            elif choice == '3':
                products = controller.list_products()
                if products:
                    ProductView.show_products(products)
                    try:
                        product_id = int(input("Entrez l'ID du produit à supprimer: "))
                        controller.delete_product(product_id)
                        print("Produit supprimé avec succès!")
                    except ValueError:
                        print("ID invalide.")
                else:
                    print("Aucun produit à supprimer.")
            elif choice == '4':
                controller.shutdown()
                break
            else:
                print("Cette option n'existe pas.")

    @staticmethod
    def show_products(products):
        """ List products """
        if not products:
            print("Aucun produit trouvé.")
        else:
            print("\n--- Liste des produits ---")
            for product in products:
                print(f"ID: {product.id} | {product.name} | Marque: {product.brand} | Prix: {product.price}€")

    @staticmethod
    def get_inputs():
        """ Prompt user for inputs necessary to add a new product """
        name = input("Nom du produit : ").strip()
        brand = input("Marque : ").strip()
        while True:
            try:
                price = float(input("Prix : ").strip())
                break
            except ValueError:
                print("Veuillez entrer un prix valide.")
        return name, brand, price
