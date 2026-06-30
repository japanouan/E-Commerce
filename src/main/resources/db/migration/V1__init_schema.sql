-- ============================================================
-- E-Commerce Schema for Supabase (PostgreSQL)
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- AUTH & USER
-- ============================================================

CREATE TABLE role (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(50) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE role_permission (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  role_id UUID NOT NULL REFERENCES role(id) ON DELETE CASCADE,
  permission VARCHAR(100) NOT NULL,
  UNIQUE(role_id, permission)
);

CREATE TABLE "user" (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  phone VARCHAR(20),
  role_id UUID NOT NULL REFERENCES role(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE address (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
  label VARCHAR(50),                     -- e.g. "Home", "Office"
  full_address TEXT NOT NULL,
  province VARCHAR(100) NOT NULL,
  postal_code VARCHAR(10) NOT NULL,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- PRODUCT CATALOG
-- ============================================================

CREATE TABLE brand (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL UNIQUE,
  logo_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE category (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  parent_id UUID REFERENCES category(id) ON DELETE SET NULL,
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(100) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE product (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  brand_id UUID REFERENCES brand(id) ON DELETE SET NULL,
  category_id UUID REFERENCES category(id) ON DELETE SET NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'archived')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE product_image (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID NOT NULL REFERENCES product(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- ATTRIBUTES (shared across products)
-- ============================================================

CREATE TABLE product_attribute (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL UNIQUE,    -- e.g. "Color", "Size"
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE product_attribute_value (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  attribute_id UUID NOT NULL REFERENCES product_attribute(id) ON DELETE CASCADE,
  value VARCHAR(100) NOT NULL,          -- e.g. "Red", "XL"
  UNIQUE(attribute_id, value)
);

-- ============================================================
-- SKU (sellable combination)
-- ============================================================

CREATE TABLE product_sku (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID NOT NULL REFERENCES product(id) ON DELETE CASCADE,
  sku_code VARCHAR(100) NOT NULL UNIQUE,
  price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
  qty INT NOT NULL DEFAULT 0 CHECK (qty >= 0),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE sku_attribute_value (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sku_id UUID NOT NULL REFERENCES product_sku(id) ON DELETE CASCADE,
  attribute_value_id UUID NOT NULL REFERENCES product_attribute_value(id) ON DELETE CASCADE,
  UNIQUE(sku_id, attribute_value_id)
);

-- ============================================================
-- COUPON
-- ============================================================

CREATE TABLE coupon (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code VARCHAR(50) NOT NULL UNIQUE,
  type VARCHAR(20) NOT NULL CHECK (type IN ('percent', 'fixed')),
  value NUMERIC(10, 2) NOT NULL CHECK (value > 0),
  max_uses INT,
  used_count INT NOT NULL DEFAULT 0,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- CART
-- ============================================================

CREATE TABLE cart (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES "user"(id) ON DELETE CASCADE,  -- 1 cart per user
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE cart_item (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cart_id UUID NOT NULL REFERENCES cart(id) ON DELETE CASCADE,
  sku_id UUID NOT NULL REFERENCES product_sku(id) ON DELETE CASCADE,
  quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
  UNIQUE(cart_id, sku_id)
);

-- ============================================================
-- ORDER
-- ============================================================

CREATE TABLE "order" (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES "user"(id),
  address_id UUID NOT NULL REFERENCES address(id),
  coupon_id UUID REFERENCES coupon(id) ON DELETE SET NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'pending' CHECK (
    status IN ('pending', 'confirmed', 'packed', 'shipping', 'delivered', 'cancelled')
  ),
  discount_amount NUMERIC(10, 2) NOT NULL DEFAULT 0,
  total_price NUMERIC(10, 2) NOT NULL CHECK (total_price >= 0),
  ordered_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE order_item (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL REFERENCES "order"(id) ON DELETE CASCADE,
  sku_id UUID NOT NULL REFERENCES product_sku(id),
  quantity INT NOT NULL CHECK (quantity > 0),
  price_at_purchase NUMERIC(10, 2) NOT NULL CHECK (price_at_purchase >= 0)  -- snapshot ราคา ณ เวลาซื้อ
);

CREATE TABLE order_status_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL REFERENCES "order"(id) ON DELETE CASCADE,
  status VARCHAR(30) NOT NULL,
  note TEXT,
  changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- PAYMENT
-- ============================================================

CREATE TABLE payment (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL UNIQUE REFERENCES "order"(id) ON DELETE CASCADE,
  method VARCHAR(50) NOT NULL,          -- e.g. "credit_card", "promptpay", "mock"
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (
    status IN ('pending', 'paid', 'failed', 'refunded')
  ),
  transaction_ref VARCHAR(255),
  amount NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- SHIPMENT (schema ready, not yet implemented)
-- ============================================================

CREATE TABLE shipment (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL UNIQUE REFERENCES "order"(id) ON DELETE CASCADE,
  tracking_number VARCHAR(100),
  courier VARCHAR(100),
  status VARCHAR(30) DEFAULT 'pending' CHECK (
    status IN ('pending', 'picked_up', 'in_transit', 'delivered', 'failed')
  ),
  estimated_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- REVIEW
-- ============================================================

CREATE TABLE review (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES product(id) ON DELETE CASCADE,
  rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, product_id)           -- 1 review per user per product
);

CREATE TABLE review_report (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  review_id UUID NOT NULL REFERENCES review(id) ON DELETE CASCADE,
  reported_by UUID NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  vote_count INT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(review_id, reported_by)        -- 1 report per user per review
);

-- ============================================================
-- INDEXES (performance)
-- ============================================================

CREATE INDEX idx_product_category ON product(category_id);
CREATE INDEX idx_product_brand ON product(brand_id);
CREATE INDEX idx_product_sku_product ON product_sku(product_id);
CREATE INDEX idx_sku_attr_val_sku ON sku_attribute_value(sku_id);
CREATE INDEX idx_order_user ON "order"(user_id);
CREATE INDEX idx_order_item_order ON order_item(order_id);
CREATE INDEX idx_order_status_history_order ON order_status_history(order_id);
CREATE INDEX idx_review_product ON review(product_id);
CREATE INDEX idx_review_report_review ON review_report(review_id);
CREATE INDEX idx_cart_item_cart ON cart_item(cart_id);

-- ============================================================
-- SEED: default roles
-- ============================================================

INSERT INTO role (name) VALUES ('admin'), ('customer');
