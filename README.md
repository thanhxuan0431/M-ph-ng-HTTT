# M-ph-ng-HTTT

## Hướng dẫn đồng bộ tài liệu DOCX/SQL lên môi trường chấm bài

1. **Thêm file vào thư mục dự án** trên máy của bạn (ví dụ `tai_lieu.docx`, `co_so_du_lieu.sql`).
2. Mở terminal tại thư mục dự án và chạy các lệnh Git sau:
   ```bash
   git add tai_lieu.docx co_so_du_lieu.sql
   git commit -m "Add tai lieu va co so du lieu"
   git push origin <ten-nhanh>
   ```
   Thay `<ten-nhanh>` bằng tên nhánh bạn đang làm việc (ví dụ `main` hoặc `work`).
3. Trong môi trường chấm bài/AutoGrader, **chạy `git pull`** để lấy các thay đổi mới nhất:
   ```bash
   git pull
   ```
4. Kiểm tra lại bằng `ls` hoặc `find` để đảm bảo file `.docx` và `.sql` đã xuất hiện.
5. Nếu không thấy file, kiểm tra lại nhánh đang làm việc (`git branch --show-current`) và chắc chắn bạn đã push đúng kho Git.

Làm theo các bước trên giúp nội dung tài liệu và cơ sở dữ liệu khả dụng để xây dựng hướng dẫn chi tiết theo yêu cầu của bạn.
