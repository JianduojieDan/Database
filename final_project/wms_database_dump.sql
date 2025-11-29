--
-- PostgreSQL database dump
--

-- Dumped from database version 14.19 (Homebrew)
-- Dumped by pg_dump version 17.5

-- Started on 2025-11-29 22:29:37 +06

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 4 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 215 (class 1259 OID 24966)
-- Name: customer_orders; Type: TABLE; Schema: public; Owner: Dan
--

CREATE TABLE public.customer_orders (
    order_id integer NOT NULL,
    customer_name character varying(255),
    order_status character varying(50) DEFAULT 'Pending'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.customer_orders OWNER TO "Dan";

--
-- TOC entry 214 (class 1259 OID 24965)
-- Name: customer_orders_order_id_seq; Type: SEQUENCE; Schema: public; Owner: Dan
--

CREATE SEQUENCE public.customer_orders_order_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.customer_orders_order_id_seq OWNER TO "Dan";

--
-- TOC entry 3738 (class 0 OID 0)
-- Dependencies: 214
-- Name: customer_orders_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: Dan
--

ALTER SEQUENCE public.customer_orders_order_id_seq OWNED BY public.customer_orders.order_id;


--
-- TOC entry 213 (class 1259 OID 24949)
-- Name: inventory; Type: TABLE; Schema: public; Owner: Dan
--

CREATE TABLE public.inventory (
    product_id integer NOT NULL,
    warehouse_id integer NOT NULL,
    quantity_on_hand integer NOT NULL,
    CONSTRAINT inventory_quantity_on_hand_check CHECK ((quantity_on_hand >= 0))
);


ALTER TABLE public.inventory OWNER TO "Dan";

--
-- TOC entry 217 (class 1259 OID 24975)
-- Name: order_items; Type: TABLE; Schema: public; Owner: Dan
--

CREATE TABLE public.order_items (
    item_id integer NOT NULL,
    order_id integer,
    product_id integer,
    quantity_requested integer NOT NULL,
    CONSTRAINT order_items_quantity_requested_check CHECK ((quantity_requested > 0))
);


ALTER TABLE public.order_items OWNER TO "Dan";

--
-- TOC entry 216 (class 1259 OID 24974)
-- Name: order_items_item_id_seq; Type: SEQUENCE; Schema: public; Owner: Dan
--

CREATE SEQUENCE public.order_items_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.order_items_item_id_seq OWNER TO "Dan";

--
-- TOC entry 3739 (class 0 OID 0)
-- Dependencies: 216
-- Name: order_items_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: Dan
--

ALTER SEQUENCE public.order_items_item_id_seq OWNED BY public.order_items.item_id;


--
-- TOC entry 210 (class 1259 OID 24933)
-- Name: products; Type: TABLE; Schema: public; Owner: Dan
--

CREATE TABLE public.products (
    name character varying(255),
    product_id integer NOT NULL,
    sku character varying(50) NOT NULL
);


ALTER TABLE public.products OWNER TO "Dan";

--
-- TOC entry 209 (class 1259 OID 24932)
-- Name: products_product_id_seq; Type: SEQUENCE; Schema: public; Owner: Dan
--

CREATE SEQUENCE public.products_product_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.products_product_id_seq OWNER TO "Dan";

--
-- TOC entry 3740 (class 0 OID 0)
-- Dependencies: 209
-- Name: products_product_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: Dan
--

ALTER SEQUENCE public.products_product_id_seq OWNED BY public.products.product_id;


--
-- TOC entry 219 (class 1259 OID 24993)
-- Name: stock_movements; Type: TABLE; Schema: public; Owner: Dan
--

CREATE TABLE public.stock_movements (
    movement_id integer NOT NULL,
    product_id integer,
    warehouse_id integer,
    quantity_change integer NOT NULL,
    reason character varying(200),
    movement_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.stock_movements OWNER TO "Dan";

--
-- TOC entry 218 (class 1259 OID 24992)
-- Name: stock_movements_movement_id_seq; Type: SEQUENCE; Schema: public; Owner: Dan
--

CREATE SEQUENCE public.stock_movements_movement_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.stock_movements_movement_id_seq OWNER TO "Dan";

--
-- TOC entry 3741 (class 0 OID 0)
-- Dependencies: 218
-- Name: stock_movements_movement_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: Dan
--

ALTER SEQUENCE public.stock_movements_movement_id_seq OWNED BY public.stock_movements.movement_id;


--
-- TOC entry 212 (class 1259 OID 24943)
-- Name: warehouses; Type: TABLE; Schema: public; Owner: Dan
--

CREATE TABLE public.warehouses (
    warehouse_id integer NOT NULL,
    location_name character varying(255) NOT NULL
);


ALTER TABLE public.warehouses OWNER TO "Dan";

--
-- TOC entry 211 (class 1259 OID 24942)
-- Name: warehouses_warehouse_id_seq; Type: SEQUENCE; Schema: public; Owner: Dan
--

CREATE SEQUENCE public.warehouses_warehouse_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.warehouses_warehouse_id_seq OWNER TO "Dan";

--
-- TOC entry 3742 (class 0 OID 0)
-- Dependencies: 211
-- Name: warehouses_warehouse_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: Dan
--

ALTER SEQUENCE public.warehouses_warehouse_id_seq OWNED BY public.warehouses.warehouse_id;


--
-- TOC entry 3554 (class 2604 OID 24969)
-- Name: customer_orders order_id; Type: DEFAULT; Schema: public; Owner: Dan
--

ALTER TABLE ONLY public.customer_orders ALTER COLUMN order_id SET DEFAULT nextval('public.customer_orders_order_id_seq'::regclass);


--
-- TOC entry 3557 (class 2604 OID 24978)
-- Name: order_items item_id; Type: DEFAULT; Schema: public; Owner: Dan
--

ALTER TABLE ONLY public.order_items ALTER COLUMN item_id SET DEFAULT nextval('public.order_items_item_id_seq'::regclass);


--
-- TOC entry 3552 (class 2604 OID 24936)
-- Name: products product_id; Type: DEFAULT; Schema: public; Owner: Dan
--

ALTER TABLE ONLY public.products ALTER COLUMN product_id SET DEFAULT nextval('public.products_product_id_seq'::regclass);


--
-- TOC entry 3558 (class 2604 OID 24996)
-- Name: stock_movements movement_id; Type: DEFAULT; Schema: public; Owner: Dan
--

ALTER TABLE ONLY public.stock_movements ALTER COLUMN movement_id SET DEFAULT nextval('public.stock_movements_movement_id_seq'::regclass);


--
-- TOC entry 3553 (class 2604 OID 24946)
-- Name: warehouses warehouse_id; Type: DEFAULT; Schema: public; Owner: Dan
--

ALTER TABLE ONLY public.warehouses ALTER COLUMN warehouse_id SET DEFAULT nextval('public.warehouses_warehouse_id_seq'::regclass);


--
-- TOC entry 3727 (class 0 OID 24966)
-- Dependencies: 215
-- Data for Name: customer_orders; Type: TABLE DATA; Schema: public; Owner: Dan
--

COPY public.customer_orders (order_id, customer_name, order_status, created_at) FROM stdin;
4	User-19	Fulfilled	2025-11-29 22:13:44.693254
7	User-16	Fulfilled	2025-11-29 22:13:44.707031
6	User-2	Fulfilled	2025-11-29 22:13:44.703467
8	User-7	Fulfilled	2025-11-29 22:13:44.717809
3	User-6	Fulfilled	2025-11-29 22:13:44.691311
\.


--
-- TOC entry 3725 (class 0 OID 24949)
-- Dependencies: 213
-- Data for Name: inventory; Type: TABLE DATA; Schema: public; Owner: Dan
--

COPY public.inventory (product_id, warehouse_id, quantity_on_hand) FROM stdin;
2	1	100
3	2	50
5	1	0
\.


--
-- TOC entry 3729 (class 0 OID 24975)
-- Dependencies: 217
-- Data for Name: order_items; Type: TABLE DATA; Schema: public; Owner: Dan
--

COPY public.order_items (item_id, order_id, product_id, quantity_requested) FROM stdin;
2	4	5	1
3	3	5	1
6	6	5	1
7	7	5	1
8	8	5	1
\.


--
-- TOC entry 3722 (class 0 OID 24933)
-- Dependencies: 210
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: Dan
--

COPY public.products (name, product_id, sku) FROM stdin;
iPhone 15 Pro Blue	2	IPHONE-15-PRO-BLUE
Samsung S24 Black	3	SAMSUNG-S24-BLACK
iPhone 15 Pro 256GB	5	IPHONE-15-PRO
MacBook Pro M3 16GB	6	MACBOOK-M3-PRO
AirPods Pro 2nd Gen	7	AIRPODS-PRO-2
\.


--
-- TOC entry 3731 (class 0 OID 24993)
-- Dependencies: 219
-- Data for Name: stock_movements; Type: TABLE DATA; Schema: public; Owner: Dan
--

COPY public.stock_movements (movement_id, product_id, warehouse_id, quantity_change, reason, movement_time) FROM stdin;
3	5	1	-1	Order 4 Fulfilled	2025-11-29 22:13:44.693254
4	5	1	-1	Order 7 Fulfilled	2025-11-29 22:13:44.707031
5	5	1	-1	Order 6 Fulfilled	2025-11-29 22:13:44.703467
6	5	1	-1	Order 8 Fulfilled	2025-11-29 22:13:44.717809
7	5	1	-1	Order 3 Fulfilled	2025-11-29 22:13:44.691311
\.


--
-- TOC entry 3724 (class 0 OID 24943)
-- Dependencies: 212
-- Data for Name: warehouses; Type: TABLE DATA; Schema: public; Owner: Dan
--

COPY public.warehouses (warehouse_id, location_name) FROM stdin;
1	比什凯克中心仓
2	奥什分仓
3	托克马克仓
4	Main Distribution Center (Bishkek)
5	Express Store (Osh)
\.


--
-- TOC entry 3743 (class 0 OID 0)
-- Dependencies: 214
-- Name: customer_orders_order_id_seq; Type: SEQUENCE SET; Schema: public; Owner: Dan
--

SELECT pg_catalog.setval('public.customer_orders_order_id_seq', 21, true);


--
-- TOC entry 3744 (class 0 OID 0)
-- Dependencies: 216
-- Name: order_items_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: Dan
--

SELECT pg_catalog.setval('public.order_items_item_id_seq', 21, true);


--
-- TOC entry 3745 (class 0 OID 0)
-- Dependencies: 209
-- Name: products_product_id_seq; Type: SEQUENCE SET; Schema: public; Owner: Dan
--

SELECT pg_catalog.setval('public.products_product_id_seq', 7, true);


--
-- TOC entry 3746 (class 0 OID 0)
-- Dependencies: 218
-- Name: stock_movements_movement_id_seq; Type: SEQUENCE SET; Schema: public; Owner: Dan
--

SELECT pg_catalog.setval('public.stock_movements_movement_id_seq', 7, true);


--
-- TOC entry 3747 (class 0 OID 0)
-- Dependencies: 211
-- Name: warehouses_warehouse_id_seq; Type: SEQUENCE SET; Schema: public; Owner: Dan
--

SELECT pg_catalog.setval('public.warehouses_warehouse_id_seq', 5, true);


--
-- TOC entry 3571 (class 2606 OID 24973)
-- Name: customer_orders customer_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: Dan
--

ALTER TABLE ONLY public.customer_orders
    ADD CONSTRAINT customer_orders_pkey PRIMARY KEY (order_id);


--
-- TOC entry 3569 (class 2606 OID 24954)
-- Name: inventory inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: Dan
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_pkey PRIMARY KEY (product_id, warehouse_id);


--
-- TOC entry 3573 (class 2606 OID 24981)
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: Dan
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (item_id);


--
-- TOC entry 3563 (class 2606 OID 24939)
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: Dan
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (product_id);


--
-- TOC entry 3565 (class 2606 OID 24941)
-- Name: products products_sku_key; Type: CONSTRAINT; Schema: public; Owner: Dan
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_sku_key UNIQUE (sku);


--
-- TOC entry 3575 (class 2606 OID 24999)
-- Name: stock_movements stock_movements_pkey; Type: CONSTRAINT; Schema: public; Owner: Dan
--

ALTER TABLE ONLY public.stock_movements
    ADD CONSTRAINT stock_movements_pkey PRIMARY KEY (movement_id);


--
-- TOC entry 3567 (class 2606 OID 24948)
-- Name: warehouses warehouses_pkey; Type: CONSTRAINT; Schema: public; Owner: Dan
--

ALTER TABLE ONLY public.warehouses
    ADD CONSTRAINT warehouses_pkey PRIMARY KEY (warehouse_id);


--
-- TOC entry 3576 (class 2606 OID 24955)
-- Name: inventory inventory_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Dan
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id) ON DELETE CASCADE;


--
-- TOC entry 3577 (class 2606 OID 24960)
-- Name: inventory inventory_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Dan
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(warehouse_id) ON DELETE CASCADE;


--
-- TOC entry 3578 (class 2606 OID 24982)
-- Name: order_items order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Dan
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.customer_orders(order_id);


--
-- TOC entry 3579 (class 2606 OID 24987)
-- Name: order_items order_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Dan
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id);


--
-- TOC entry 3580 (class 2606 OID 25000)
-- Name: stock_movements stock_movements_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Dan
--

ALTER TABLE ONLY public.stock_movements
    ADD CONSTRAINT stock_movements_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(product_id);


--
-- TOC entry 3581 (class 2606 OID 25005)
-- Name: stock_movements stock_movements_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: Dan
--

ALTER TABLE ONLY public.stock_movements
    ADD CONSTRAINT stock_movements_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(warehouse_id);


--
-- TOC entry 3737 (class 0 OID 0)
-- Dependencies: 4
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2025-11-29 22:29:37 +06

--
-- PostgreSQL database dump complete
--

