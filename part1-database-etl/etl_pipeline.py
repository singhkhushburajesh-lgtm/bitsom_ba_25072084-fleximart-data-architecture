"""
FlexiMart ETL Pipeline
This script extracts data from CSV files, transforms it by cleaning data quality issues,
and loads it into a MySQL/PostgreSQL database.

Author: Data Engineering Team
Date: January 2026
"""

import pandas as pd
import mysql.connector
from mysql.connector import Error
import re
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('etl_pipeline.log'),
        logging.StreamHandler()
    ]
)

class DataQualityReport:
    """Class to track data quality metrics throughout the ETL process"""
    def __init__(self):
        self.metrics = {
            'customers': {'raw': 0, 'duplicates': 0, 'missing_handled': 0, 'loaded': 0},
            'products': {'raw': 0, 'duplicates': 0, 'missing_handled': 0, 'loaded': 0},
            'sales': {'raw': 0, 'duplicates': 0, 'missing_handled': 0, 'loaded': 0}
        }
    
    def update(self, dataset, metric, value):
        """Update a specific metric for a dataset"""
        self.metrics[dataset][metric] = value
    
    def generate_report(self, filename='data_quality_report.txt'):
        """Generate a detailed data quality report"""
        with open(filename, 'w') as f:
            f.write("="*70 + "\n")
            f.write("FLEXIMART ETL PIPELINE - DATA QUALITY REPORT\n")
            f.write("="*70 + "\n")
            f.write(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
            
            for dataset, metrics in self.metrics.items():
                f.write(f"\n{dataset.upper()} DATASET\n")
                f.write("-"*70 + "\n")
                f.write(f"Records in raw file:              {metrics['raw']}\n")
                f.write(f"Duplicate records removed:        {metrics['duplicates']}\n")
                f.write(f"Missing values handled:           {metrics['missing_handled']}\n")
                f.write(f"Records loaded successfully:      {metrics['loaded']}\n")
                f.write(f"Data quality score:               {(metrics['loaded']/metrics['raw']*100):.2f}%\n")
            
            total_raw = sum(m['raw'] for m in self.metrics.values())
            total_loaded = sum(m['loaded'] for m in self.metrics.values())
            
            f.write("\n" + "="*70 + "\n")
            f.write("OVERALL SUMMARY\n")
            f.write("="*70 + "\n")
            f.write(f"Total records processed:          {total_raw}\n")
            f.write(f"Total records loaded:             {total_loaded}\n")
            f.write(f"Overall success rate:             {(total_loaded/total_raw*100):.2f}%\n")
            f.write("="*70 + "\n")
        
        logging.info(f"Data quality report generated: {filename}")


class FlexiMartETL:
    """Main ETL class for FlexiMart data pipeline"""
    
    def __init__(self, db_config):
        """Initialize ETL pipeline with database configuration"""
        self.db_config = db_config
        self.conn = None
        self.report = DataQualityReport()
    
    def connect_to_database(self):
        """Establish connection to MySQL/PostgreSQL database"""
        try:
            self.conn = mysql.connector.connect(**self.db_config)
            if self.conn.is_connected():
                logging.info("Successfully connected to database")
                return True
        except Error as e:
            logging.error(f"Database connection failed: {e}")
            return False
    
    def close_connection(self):
        """Close database connection"""
        if self.conn and self.conn.is_connected():
            self.conn.close()
            logging.info("Database connection closed")
    
    # ==================== EXTRACT PHASE ====================
    
    def extract_customers(self, filepath='customers_raw.csv'):
        """Extract customer data from CSV file"""
        try:
            df = pd.read_csv(filepath)
            self.report.update('customers', 'raw', len(df))
            logging.info(f"Extracted {len(df)} customer records")
            return df
        except Exception as e:
            logging.error(f"Failed to extract customers: {e}")
            return None
    
    def extract_products(self, filepath='products_raw.csv'):
        """Extract product data from CSV file"""
        try:
            df = pd.read_csv(filepath)
            self.report.update('products', 'raw', len(df))
            logging.info(f"Extracted {len(df)} product records")
            return df
        except Exception as e:
            logging.error(f"Failed to extract products: {e}")
            return None
    
    def extract_sales(self, filepath='sales_raw.csv'):
        """Extract sales transaction data from CSV file"""
        try:
            df = pd.read_csv(filepath)
            self.report.update('sales', 'raw', len(df))
            logging.info(f"Extracted {len(df)} sales records")
            return df
        except Exception as e:
            logging.error(f"Failed to extract sales: {e}")
            return None
    
    # ==================== TRANSFORM PHASE ====================
    
    def standardize_phone(self, phone):
        """Standardize phone numbers to +91-XXXXXXXXXX format"""
        if pd.isna(phone):
            return None
        
        # Remove all non-digit characters
        phone_digits = re.sub(r'\D', '', str(phone))
        
        # Remove leading 91 if present
        if phone_digits.startswith('91') and len(phone_digits) > 10:
            phone_digits = phone_digits[2:]
        
        # Keep only first 10 digits
        phone_digits = phone_digits[:10]
        
        # Format as +91-XXXXXXXXXX
        if len(phone_digits) == 10:
            return f"+91-{phone_digits}"
        return None
    
    def standardize_date(self, date_str):
        """Convert various date formats to YYYY-MM-DD"""
        if pd.isna(date_str):
            return None
        
        # Try different date formats
        formats = ['%Y-%m-%d', '%d/%m/%Y', '%m-%d-%Y', '%d-%m-%Y', '%m/%d/%Y']
        
        for fmt in formats:
            try:
                date_obj = datetime.strptime(str(date_str), fmt)
                return date_obj.strftime('%Y-%m-%d')
            except ValueError:
                continue
        
        logging.warning(f"Could not parse date: {date_str}")
        return None
    
    def transform_customers(self, df):
        """Clean and transform customer data"""
        logging.info("Starting customer data transformation...")
        
        initial_count = len(df)
        missing_before = df.isnull().sum().sum()
        
        # Remove duplicate records based on customer_id
        duplicates = df.duplicated(subset=['customer_id'], keep='first').sum()
        df = df.drop_duplicates(subset=['customer_id'], keep='first')
        self.report.update('customers', 'duplicates', duplicates)
        logging.info(f"Removed {duplicates} duplicate customer records")
        
        # Handle missing emails - drop records with missing emails as email is required
        rows_with_missing_email = df['email'].isna().sum()
        df = df.dropna(subset=['email'])
        
        # Standardize phone numbers
        df['phone'] = df['phone'].apply(self.standardize_phone)
        
        # Standardize city names (title case)
        df['city'] = df['city'].str.strip().str.title()
        
        # Standardize dates
        df['registration_date'] = df['registration_date'].apply(self.standardize_date)
        
        # Strip whitespace from text fields
        df['first_name'] = df['first_name'].str.strip()
        df['last_name'] = df['last_name'].str.strip()
        df['email'] = df['email'].str.strip().str.lower()
        
        # Count missing values handled
        missing_after = df.isnull().sum().sum()
        handled = missing_before - missing_after + rows_with_missing_email
        self.report.update('customers', 'missing_handled', handled)
        
        logging.info(f"Customer transformation complete: {len(df)} clean records")
        return df
    
    def transform_products(self, df):
        """Clean and transform product data"""
        logging.info("Starting product data transformation...")
        
        initial_count = len(df)
        missing_before = df.isnull().sum().sum()
        
        # Remove duplicates based on product_id
        duplicates = df.duplicated(subset=['product_id'], keep='first').sum()
        df = df.drop_duplicates(subset=['product_id'], keep='first')
        self.report.update('products', 'duplicates', duplicates)
        
        # Handle missing prices - drop records with missing prices as price is required
        rows_with_missing_price = df['price'].isna().sum()
        df = df.dropna(subset=['price'])
        
        # Standardize category names (title case)
        df['category'] = df['category'].str.strip().str.title()
        
        # Handle missing stock - set to 0 as default
        df['stock_quantity'] = df['stock_quantity'].fillna(0).astype(int)
        
        # Strip whitespace from product names
        df['product_name'] = df['product_name'].str.strip()
        
        # Count missing values handled
        missing_after = df.isnull().sum().sum()
        handled = missing_before - missing_after + rows_with_missing_price
        self.report.update('products', 'missing_handled', handled)
        
        logging.info(f"Product transformation complete: {len(df)} clean records")
        return df
    
    def transform_sales(self, df):
        """Clean and transform sales transaction data"""
        logging.info("Starting sales data transformation...")
        
        initial_count = len(df)
        missing_before = df.isnull().sum().sum()
        
        # Remove duplicate transactions based on transaction_id
        duplicates = df.duplicated(subset=['transaction_id'], keep='first').sum()
        df = df.drop_duplicates(subset=['transaction_id'], keep='first')
        self.report.update('sales', 'duplicates', duplicates)
        logging.info(f"Removed {duplicates} duplicate sales records")
        
        # Handle missing customer_id and product_id - drop these records as they're critical
        rows_with_missing_ids = df['customer_id'].isna().sum() + df['product_id'].isna().sum()
        df = df.dropna(subset=['customer_id', 'product_id'])
        
        # Standardize dates
        df['transaction_date'] = df['transaction_date'].apply(self.standardize_date)
        
        # Calculate subtotal for each transaction
        df['subtotal'] = df['quantity'] * df['unit_price']
        
        # Strip whitespace from status
        df['status'] = df['status'].str.strip()
        
        # Count missing values handled
        missing_after = df.isnull().sum().sum()
        handled = missing_before - missing_after + rows_with_missing_ids
        self.report.update('sales', 'missing_handled', handled)
        
        logging.info(f"Sales transformation complete: {len(df)} clean records")
        return df
    
    # ==================== LOAD PHASE ====================
    
    def load_customers(self, df):
        """Load cleaned customer data into database"""
        try:
            cursor = self.conn.cursor()
            
            # Create a mapping of old customer_id to new auto-generated ones
            self.customer_id_map = {}
            
            insert_query = """
                INSERT INTO customers (first_name, last_name, email, phone, city, registration_date)
                VALUES (%s, %s, %s, %s, %s, %s)
            """
            
            loaded_count = 0
            for _, row in df.iterrows():
                try:
                    cursor.execute(insert_query, (
                        row['first_name'],
                        row['last_name'],
                        row['email'],
                        row['phone'],
                        row['city'],
                        row['registration_date']
                    ))
                    
                    # Map old customer_id to new auto-generated id
                    new_id = cursor.lastrowid
                    self.customer_id_map[row['customer_id']] = new_id
                    loaded_count += 1
                    
                except Error as e:
                    logging.warning(f"Failed to insert customer {row['customer_id']}: {e}")
            
            self.conn.commit()
            self.report.update('customers', 'loaded', loaded_count)
            logging.info(f"Loaded {loaded_count} customers into database")
            
        except Error as e:
            logging.error(f"Failed to load customers: {e}")
            self.conn.rollback()
    
    def load_products(self, df):
        """Load cleaned product data into database"""
        try:
            cursor = self.conn.cursor()
            
            # Create a mapping of old product_id to new auto-generated ones
            self.product_id_map = {}
            
            insert_query = """
                INSERT INTO products (product_name, category, price, stock_quantity)
                VALUES (%s, %s, %s, %s)
            """
            
            loaded_count = 0
            for _, row in df.iterrows():
                try:
                    cursor.execute(insert_query, (
                        row['product_name'],
                        row['category'],
                        float(row['price']),
                        int(row['stock_quantity'])
                    ))
                    
                    # Map old product_id to new auto-generated id
                    new_id = cursor.lastrowid
                    self.product_id_map[row['product_id']] = new_id
                    loaded_count += 1
                    
                except Error as e:
                    logging.warning(f"Failed to insert product {row['product_id']}: {e}")
            
            self.conn.commit()
            self.report.update('products', 'loaded', loaded_count)
            logging.info(f"Loaded {loaded_count} products into database")
            
        except Error as e:
            logging.error(f"Failed to load products: {e}")
            self.conn.rollback()
    
    def load_sales(self, df):
        """Load cleaned sales data into orders and order_items tables"""
        try:
            cursor = self.conn.cursor()
            
            # Group transactions by customer and date to create orders
            df['order_key'] = df['customer_id'] + '_' + df['transaction_date'].astype(str)
            
            orders_created = {}
            loaded_count = 0
            
            for order_key, group in df.groupby('order_key'):
                customer_id = group.iloc[0]['customer_id']
                order_date = group.iloc[0]['transaction_date']
                status = group.iloc[0]['status']
                
                # Map old customer_id to new database id
                if customer_id not in self.customer_id_map:
                    logging.warning(f"Customer {customer_id} not found in mapping, skipping order")
                    continue
                
                new_customer_id = self.customer_id_map[customer_id]
                
                # Calculate total amount for the order
                total_amount = group['subtotal'].sum()
                
                try:
                    # Insert into orders table
                    insert_order = """
                        INSERT INTO orders (customer_id, order_date, total_amount, status)
                        VALUES (%s, %s, %s, %s)
                    """
                    cursor.execute(insert_order, (new_customer_id, order_date, total_amount, status))
                    order_id = cursor.lastrowid
                    
                    # Insert items for this order
                    insert_item = """
                        INSERT INTO order_items (order_id, product_id, quantity, unit_price, subtotal)
                        VALUES (%s, %s, %s, %s, %s)
                    """
                    
                    for _, item in group.iterrows():
                        product_id = item['product_id']
                        
                        # Map old product_id to new database id
                        if product_id not in self.product_id_map:
                            logging.warning(f"Product {product_id} not found in mapping, skipping item")
                            continue
                        
                        new_product_id = self.product_id_map[product_id]
                        
                        cursor.execute(insert_item, (
                            order_id,
                            new_product_id,
                            int(item['quantity']),
                            float(item['unit_price']),
                            float(item['subtotal'])
                        ))
                        loaded_count += 1
                    
                except Error as e:
                    logging.warning(f"Failed to insert order for {order_key}: {e}")
            
            self.conn.commit()
            self.report.update('sales', 'loaded', loaded_count)
            logging.info(f"Loaded {loaded_count} order items into database")
            
        except Error as e:
            logging.error(f"Failed to load sales: {e}")
            self.conn.rollback()
    
    # ==================== MAIN ETL PROCESS ====================
    
    def run_etl(self):
        """Execute the complete ETL pipeline"""
        logging.info("="*70)
        logging.info("STARTING FLEXIMART ETL PIPELINE")
        logging.info("="*70)
        
        # Connect to database
        if not self.connect_to_database():
            logging.error("ETL pipeline aborted due to database connection failure")
            return
        
        try:
            # EXTRACT
            logging.info("\n--- EXTRACT PHASE ---")
            customers_raw = self.extract_customers()
            products_raw = self.extract_products()
            sales_raw = self.extract_sales()
            
            if customers_raw is None or products_raw is None or sales_raw is None:
                logging.error("Extraction failed, aborting ETL pipeline")
                return
            
            # TRANSFORM
            logging.info("\n--- TRANSFORM PHASE ---")
            customers_clean = self.transform_customers(customers_raw)
            products_clean = self.transform_products(products_raw)
            sales_clean = self.transform_sales(sales_raw)
            
            # LOAD
            logging.info("\n--- LOAD PHASE ---")
            self.load_customers(customers_clean)
            self.load_products(products_clean)
            self.load_sales(sales_clean)
            
            # Generate report
            logging.info("\n--- GENERATING REPORT ---")
            self.report.generate_report()
            
            logging.info("\n" + "="*70)
            logging.info("ETL PIPELINE COMPLETED SUCCESSFULLY")
            logging.info("="*70)
            
        except Exception as e:
            logging.error(f"ETL pipeline failed: {e}")
        finally:
            self.close_connection()


# ==================== MAIN EXECUTION ====================

if __name__ == "__main__":
    # Database configuration - UPDATE THESE WITH YOUR DATABASE CREDENTIALS
    db_config = {
        'host': 'localhost',
        'database': 'fleximart',
        'user': 'root',        # Change this to your MySQL username
        'password': 'password'  # Change this to your MySQL password
    }
    
    # Initialize and run ETL pipeline
    etl = FlexiMartETL(db_config)
    etl.run_etl()
    
    print("\nETL Pipeline execution completed!")
    print("Check 'etl_pipeline.log' for detailed logs")
    print("Check 'data_quality_report.txt' for data quality metrics")