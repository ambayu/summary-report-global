# API Route Structure - Flutter Mobile (Summary Report Cafe)

## 1. Tujuan
Dokumen ini menjadi acuan endpoint backend untuk aplikasi Flutter mobile.

Konvensi:
- Base URL: `/api/v1`
- Semua endpoint protected memakai JWT kecuali auth public.
- Format list response: `items` + `meta`.

## 2. Authentication & Session
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/logout`
- `POST /api/v1/auth/refresh`
- `GET /api/v1/auth/me`
- `POST /api/v1/auth/forgot-password`
- `POST /api/v1/auth/reset-password`

Mobile session endpoint:
- `POST /api/v1/auth/device-token` -> simpan/update FCM token
- `DELETE /api/v1/auth/device-token` -> hapus token device saat logout

## 3. Dashboard
- `GET /api/v1/dashboard/summary`
- `GET /api/v1/dashboard/revenue-trend`
- `GET /api/v1/dashboard/stock-alerts`

## 4. Transaksi
- `GET /api/v1/transactions`
- `POST /api/v1/transactions`
- `GET /api/v1/transactions/:transactionId`
- `PATCH /api/v1/transactions/:transactionId`
- `POST /api/v1/transactions/:transactionId/cancel`
- `POST /api/v1/transactions/:transactionId/split-bill`
- `POST /api/v1/transactions/:transactionId/merge`
- `GET /api/v1/transactions/:transactionId/receipt`

Item transaksi:
- `POST /api/v1/transactions/:transactionId/items`
- `PATCH /api/v1/transactions/:transactionId/items/:itemId`
- `DELETE /api/v1/transactions/:transactionId/items/:itemId`

## 5. Pembayaran
- `GET /api/v1/payments`
- `POST /api/v1/payments`
- `GET /api/v1/payments/:paymentId`
- `POST /api/v1/payments/:paymentId/refund`

## 6. Produk & Kategori
Produk:
- `GET /api/v1/products`
- `POST /api/v1/products`
- `GET /api/v1/products/:productId`
- `PATCH /api/v1/products/:productId`
- `DELETE /api/v1/products/:productId`

Kategori:
- `GET /api/v1/categories`
- `POST /api/v1/categories`
- `PATCH /api/v1/categories/:categoryId`
- `DELETE /api/v1/categories/:categoryId`

Promo produk:
- `GET /api/v1/product-promos`
- `POST /api/v1/product-promos`
- `PATCH /api/v1/product-promos/:promoId`
- `DELETE /api/v1/product-promos/:promoId`

## 7. Pelanggan
- `GET /api/v1/customers`
- `POST /api/v1/customers`
- `GET /api/v1/customers/:customerId`
- `PATCH /api/v1/customers/:customerId`
- `GET /api/v1/customers/:customerId/purchases`
- `GET /api/v1/customers/:customerId/points`
- `POST /api/v1/customers/:customerId/points/adjust`

## 8. Meja / Order Dine-In
- `GET /api/v1/tables`
- `POST /api/v1/tables`
- `PATCH /api/v1/tables/:tableId`
- `POST /api/v1/tables/:tableId/move`
- `POST /api/v1/tables/:tableId/merge-order`

## 9. Laporan
- `GET /api/v1/reports/sales/daily`
- `GET /api/v1/reports/sales/weekly`
- `GET /api/v1/reports/sales/monthly`
- `GET /api/v1/reports/sales/by-product`
- `GET /api/v1/reports/sales/by-category`
- `GET /api/v1/reports/sales/by-cashier`
- `GET /api/v1/reports/sales/by-payment-method`
- `GET /api/v1/reports/sales/discount`
- `GET /api/v1/reports/sales/refund`
- `GET /api/v1/reports/profit/simple`

Export:
- `GET /api/v1/reports/export/excel`
- `GET /api/v1/reports/export/pdf`

## 10. Pengeluaran
- `GET /api/v1/expenses`
- `POST /api/v1/expenses`
- `GET /api/v1/expenses/:expenseId`
- `PATCH /api/v1/expenses/:expenseId`
- `DELETE /api/v1/expenses/:expenseId`

Kategori pengeluaran:
- `GET /api/v1/expense-categories`
- `POST /api/v1/expense-categories`
- `PATCH /api/v1/expense-categories/:categoryId`
- `DELETE /api/v1/expense-categories/:categoryId`

Laporan pengeluaran:
- `GET /api/v1/expenses/reports/summary`
- `GET /api/v1/expenses/reports/profit-loss`

## 11. User Management
Users:
- `GET /api/v1/users`
- `POST /api/v1/users`
- `GET /api/v1/users/:userId`
- `PATCH /api/v1/users/:userId`
- `POST /api/v1/users/:userId/reset-password`
- `DELETE /api/v1/users/:userId`

Roles & permissions:
- `GET /api/v1/roles`
- `POST /api/v1/roles`
- `PATCH /api/v1/roles/:roleId`
- `DELETE /api/v1/roles/:roleId`
- `GET /api/v1/permissions`
- `POST /api/v1/roles/:roleId/permissions`

Aktivitas user:
- `GET /api/v1/user-activities`

## 12. Pengaturan
- `GET /api/v1/settings`
- `PATCH /api/v1/settings`
- `GET /api/v1/settings/profile`
- `PATCH /api/v1/settings/profile`
- `GET /api/v1/settings/payments`
- `PATCH /api/v1/settings/payments`
- `GET /api/v1/settings/tax-service`
- `PATCH /api/v1/settings/tax-service`
- `GET /api/v1/settings/printer`
- `PATCH /api/v1/settings/printer`
- `GET /api/v1/settings/receipt-format`
- `PATCH /api/v1/settings/receipt-format`
- `POST /api/v1/settings/backup`

## 13. Uploads
- `POST /api/v1/uploads?kind=image`
- `POST /api/v1/uploads?kind=pdf`

## 14. Inventori (Opsional)
- `GET /api/v1/inventory/items`
- `POST /api/v1/inventory/items`
- `PATCH /api/v1/inventory/items/:itemId`
- `GET /api/v1/inventory/movements`
- `POST /api/v1/inventory/movements`
- `GET /api/v1/inventory/suppliers`
- `POST /api/v1/inventory/suppliers`

## 15. Query Standard (List Endpoint)
Parameter list:
- `page`
- `perPage`
- `search`
- `sortBy`
- `sortOrder`
- `startDate`
- `endDate`
- `branchId` (opsional)

Contoh:
- `GET /api/v1/transactions?page=1&perPage=10&status=pending&startDate=2026-04-01&endDate=2026-04-14`

## 16. Response Standard (List)
```json
{
  "items": [],
  "meta": {
    "page": 1,
    "perPage": 10,
    "totalItems": 0,
    "totalPages": 0
  }
}
```

## 17. Role Permission (High Level)
- Owner: akses penuh.
- Admin: akses operasional + laporan.
- Kasir: transaksi, pembayaran, dashboard ringkas, riwayat.
