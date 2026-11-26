# Kịch bản thuyết trình DELTA-3 (6–7 phút). FULL = số slide trong bản đầy đủ 24 slide.
SEG = [
 dict(full=1, time='0:00 – 0:20', title='Mở đầu', text=
 'Kính thưa Ban giám khảo. Chúng em xin trình bày đề tài DELTA-3 với khẩu hiệu: Phát hiện sớm – Chặn tận gốc – Cảnh báo kịp thời. Đây là hệ thống 3 lớp chống ô nhiễm nước và ngập đô thị, phát triển từ trạm quan trắc AquaSentinel AI nhóm đã chạy thử.'),
 dict(full=2, time='0:20 – 0:45', title='Vấn đề', text=
 'Mỗi mùa mưa, Đà Nẵng gặp cùng lúc 3 vấn đề. Thứ nhất, xả thải lén thường diễn ra ban đêm, khi kiểm tra thì nước đã trong lại. Thứ hai, nước mưa đợt đầu, hay còn gọi là first flush, cuốn rác, dầu nhớt và cặn bẩn trên mặt đường chảy thẳng ra kênh và biển. Thứ ba, ngập lên rất nhanh, như trận mưa lịch sử ngày 14/10/2022, trong khi nhiều người không có điện thoại để nhận cảnh báo.'),
 dict(full=3, time='0:45 – 1:10', title='Giải pháp 3 lớp', text=
 'Ba vấn đề này xảy ra ở 3 thời điểm của cùng một cơn mưa, nên DELTA-3 có 3 lớp nối tiếp nhau. Trước mưa, trạm quan trắc phát hiện sớm ô nhiễm. Khi mưa lớn, hố ga thụ động chặn rác và nước bẩn ngay tại nguồn. Trong lũ, hộp cứu hộ trên trụ điện cảnh báo trực tiếp cho người dân. Cả 3 lớp dùng chung mạng LoRa, máy chủ AI, ứng dụng di động và cổng quản lý Web.'),
 dict(full=5, time='1:10 – 1:35', title='Lớp 1 – Trạm quan trắc', text=
 'Lớp 1 là trạm quan trắc. Trạm đo liên tục 5 thông số: nhiệt độ, tổng chất rắn hòa tan TDS, độ đục, lưu lượng và mực nước. Khi vượt ngưỡng, bơm 12 vôn tự lấy mẫu nước để lưu bằng chứng. Điểm nâng cấp mới là vũ lượng kế kiểu gầu lật để đo lượng mưa ngay tại trạm.'),
 dict(full=6, time='1:35 – 1:55', title='Sơ đồ đấu nối trạm', text=
 'Đây là sơ đồ đấu nối. Vi điều khiển ESP32 đọc 5 cảm biến, điều khiển rơ-le bật bơm lấy mẫu và gửi dữ liệu qua module LoRa. Một ESP32 thứ hai ở nơi có Internet nhận gói LoRa và đẩy lên máy chủ bằng giao thức MQTT. Vũ lượng kế chỉ cần thêm 2 dây: một vào chân ngắt của ESP32, một vào mass, mỗi lần gầu lật tạo một xung.'),
 dict(full=7, time='1:55 – 2:20', title='AI và ứng dụng', text=
 'Vì sao cần vũ lượng kế? Mùa mưa nước đục lên tự nhiên, trạm cũ sẽ báo động giả liên tục. Nay AI kết hợp lượng mưa, mực nước, độ đục và TDS: đang mưa, nước dâng, TDS loãng ra là nước mưa chảy tràn; không mưa mà TDS tăng vọt vào ban đêm là dấu hiệu xả thải lén, hệ thống báo động và lấy mẫu ngay.'),
 dict(full=9, time='2:20 – 2:55', title='Lớp 2 – Hành trình nghiên cứu hố ga', text=
 'Lớp 2 là hố ga thụ động, phần nhóm đầu tư nghiên cứu nhiều nhất qua 5 phiên bản. Bản 1 và 2 dùng van Tesla chống triều ngược, nhưng van Tesla chỉ cản bớt, vẫn rò và dễ tắc rác, nên bản 3 chuyển sang van một chiều kiểu mỏ vịt bằng cao su EPDM và cửa lật. Nhưng 2 van nối tiếp làm nước thoát chậm khi mưa cực lớn, nên bản 4 tách dòng thành 2 đường. Bản 4.1 thêm hố lắng bùn ở tâm đáy.'),
 dict(full=13, time='2:55 – 3:40', title='Video mô phỏng v4.1', text=
 '(Bấm phát video, nói theo hình.) Nhờ hiệu ứng Coanda, nước bám theo mặt lưới cong và lọt qua khe 1 mi-li-mét, còn rác trượt xuống giỏ. Nước bẩn đợt đầu được giữ trong ống trữ dưới vỉa hè, rồi xả chậm về nhà máy xử lý. Mưa thường, nước đi đường A qua van mỏ vịt. Mưa cực lớn, nước dâng tới cửa tràn đặt cao hơn ống ra 300 mi-li-mét và tự chảy sang đường B qua cửa lật. Khi triều cường, cả 2 đường đều tự đóng; ống đo triều hoạt động theo nguyên lý bình thông nhau báo sớm qua LoRa. Cát lắng xuống hố lắng, công nhân chỉ cần nhấc xô lên.'),
 dict(full=14, time='3:40 – 4:00', title='Hố ga qua con số', text=
 'Với 300 mét vuông mặt đường, lưu lượng đỉnh tính theo phương pháp hợp lý là 7,5 đến 11 lít mỗi giây. Lưới Coanda xử lý được 90 đến 135 lít mỗi giây, dư khoảng 10 lần. Mỗi hố giữ lại 0,85 mét khối nước bẩn đợt đầu. Đường B thoát dự phòng khoảng 100 lít mỗi giây. Và toàn bộ hố ga không dùng điện, không mô-tơ.'),
 dict(full=16, time='4:00 – 4:25', title='Lớp 3 – Hộp cứu hộ', text=
 'Lớp 3 là hộp cứu hộ gắn trên trụ điện. Cảm biến siêu âm chống nước chĩa xuống mặt đường biến mỗi hộp thành một điểm đo ngập. Đèn tháp 3 màu có còi báo theo mức: xanh là an toàn, vàng là nước trên 10 xăng-ti-mét, đỏ là trên 30 xăng-ti-mét, không nên đi qua. Ai đi ngang cũng hiểu, không cần điện thoại. Nút SOS gửi vị trí và độ sâu nước thật về trung tâm cứu hộ.'),
 dict(full=17, time='4:25 – 4:45', title='Sơ đồ đấu nối hộp cứu hộ', text=
 'Hộp chạy bằng pin LiFePO4 12,8 vôn và tấm pin mặt trời 10 oát, giữ được 8 đến 10 ngày không có nắng. ESP32 điều khiển đèn và còi qua mạch đệm ULN2003, đọc cảm biến siêu âm qua mạch chia áp, và gửi dữ liệu bằng LoRa nên vẫn chạy khi bão làm mất điện, mất sóng 4G. Linh kiện một hộp khoảng 1,9 đến 2,7 triệu đồng.'),
 dict(full=19, time='4:45 – 5:15', title='Tính sáng tạo, tính mới', text=
 'Về tính sáng tạo: từng nguyên lý như hiệu ứng Coanda, van một chiều hay đèn tháp đã được dùng trong công nghiệp. Cái mới của DELTA-3 là cách tích hợp chúng cho hố ga hàm ếch và cho bài toán của Đà Nẵng, và ghép 3 lớp thành một hệ thống theo đúng diễn biến cơn mưa: trạm quan trắc và ống đo triều ở hố ga báo trước cho hộp cứu hộ, hộp cứu hộ báo người dân ngay tại chỗ.'),
 dict(full=20, time='5:15 – 5:35', title='Giá thành', text=
 'Về giá thành: một hộp cứu hộ khoảng 2 triệu đồng. Hố ga có 3 phương án: tối thiểu 12 đến 18 triệu, lắp vào hố ga có sẵn 23 đến 40 triệu, đầy đủ 36 đến 60 triệu. Phương án lắp vào hố có sẵn không phải đào đường, dễ áp dụng nhất.'),
 dict(full=21, time='5:35 – 5:55', title='Tính khả thi', text=
 'Về tính khả thi, mỗi rủi ro đều đã có cách xử lý trong thiết kế: báo động giả có vũ lượng kế, rác kẹt van có lưới Coanda lọc trước, mưa vượt thiết kế có đường B, mất điện có pin mặt trời và LoRa, bảo trì có module rút lên qua nắp gang. Trạm quan trắc đã chạy thử thực tế; bước tiếp theo là làm mô hình hố ga tỉ lệ 1:5 để đo.'),
 dict(full=22, time='5:55 – 6:15', title='Áp dụng tại Đà Nẵng', text=
 'Tại Đà Nẵng, trạm quan trắc có thể đặt ở các kênh và cửa xả hay bị phản ánh ô nhiễm như kênh Phú Lộc, âu thuyền Thọ Quang; hố ga lắp trên tuyến hay ngập; hộp cứu hộ ở hẻm trũng, chợ, trường học. Lộ trình đề xuất: thí điểm 1 tuyến gồm 1 trạm, 5 hố ga, 2 hộp; đo trong 1 mùa mưa rồi nhân rộng.'),
 dict(full=23, time='6:15 – 6:35', title='Nhân rộng', text=
 'Hệ thống thiết kế dạng module nên nhân rộng được: TP. Hồ Chí Minh và Cần Thơ cần lớp hố ga chống triều; Hà Nội cần giữ nước đợt đầu và cảnh báo ngập; Huế, Hội An cần hộp cứu hộ chạy pin khi bão.'),
 dict(full=24, time='6:35 – 6:55', title='Kết luận', text=
 'Tóm lại, DELTA-3 bảo vệ thành phố trước, trong và sau mỗi cơn mưa: phát hiện sớm ô nhiễm, chặn rác và nước bẩn ngay tại hố ga, và cảnh báo kịp thời cho mọi người dân. Chúng em xin chân thành cảm ơn Ban giám khảo và rất mong nhận được câu hỏi.'),
]
QA = [
 ('Hố ga có làm nước thoát chậm hơn, gây ngập thêm không?', 'Không. Lưới Coanda xử lý gấp khoảng 10 lần lưu lượng đỉnh. Khi mưa vượt thiết kế, nước tràn qua mép lưới và đường B mở thêm khoảng 100 L/s, nên hố ga không bao giờ thoát kém hơn hố ga thường.'),
 ('Vì sao bỏ van Tesla?', 'Van Tesla chỉ làm tăng trở lực dòng ngược, không đóng kín, vẫn rò khi triều; kênh hẹp dễ tắc rác. Chống triều cần van một chiều đóng kín nên nhóm chọn van mỏ vịt EPDM và cửa lật, giữ van Tesla trong thí nghiệm so sánh.'),
 ('Rác nhỏ có làm kẹt van mỏ vịt không?', 'Nước qua lưới khe 1 mm rồi mới tới van, rác lớn đã bị giữ ở giỏ. Cát mịn lắng ở hố lắng trước miệng ống ra. Van mỏ vịt không có bản lề nên ít điểm kẹt.'),
 ('Ai dọn hố ga, bao lâu một lần?', 'Cảm biến siêu âm báo giỏ đầy 75% qua LoRa. Công nhân mở nắp gang, rút module giỏ rác và nhấc xô hố lắng, không phải xuống hố. Đề xuất mùa mưa kiểm tra hằng tháng, sau 1 mùa đo thực tế sẽ chốt chu kỳ.'),
 ('AI ở đây là gì, có đáng tin không?', 'Bước đầu là mô hình phân loại dựa trên quy tắc và ngưỡng của 4 đại lượng: lượng mưa, mực nước, độ đục, TDS. Khi có thêm dữ liệu thực, nhóm huấn luyện mô hình học máy để giảm báo nhầm. Mọi cảnh báo xả thải đều kèm mẫu nước để kiểm chứng bằng phòng thí nghiệm.'),
 ('LoRa truyền được bao xa, có cần xin phép tần số?', 'Trong đô thị thường vài trăm mét đến 1–2 km tùy vật cản, ngoài trống xa hơn. Nhóm dùng băng 920–923 MHz, băng được phép cho thiết bị vô tuyến cự ly ngắn tại Việt Nam, tuân thủ công suất phát quy định.'),
 ('Chi phí cao, thành phố có đủ tiền làm hết không?', 'Không cần làm hết một lúc. Hệ thống dạng module: thí điểm 1 tuyến, ưu tiên điểm ngập và cửa xả theo dữ liệu. Phương án lắp vào hố ga có sẵn không phải đào đường, chi phí nhỏ so với các công trình chống ngập lớn.'),
 ('Điểm khác so với sản phẩm đã có?', 'Từng bộ phận đã có trên thị trường; nhóm không nói "chưa từng có". Điểm mới là tích hợp 3 lớp theo diễn biến cơn mưa, dùng chung LoRa và AI, và thiết kế hố ga thụ động riêng cho hố ga hàm ếch, có giữ nước đợt đầu, 2 đường chống triều, hố lắng và báo triều sớm.'),
]
