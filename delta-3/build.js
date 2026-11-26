const pptxgen = require('pptxgenjs');
const fs = require('fs');
const React = require('react');
const RDS = require('react-dom/server');
const sharp = require('sharp');
const fa = require('react-icons/fa');
const { applyTheme } = require('/Users/fankao/Library/Application Support/Claude/local-agent-mode-sessions/skills-plugin/3a0026ca-bf3d-43cc-a0de-cdcabb895fb1/ff4e275d-18e0-4cb4-a7f7-6d3f813d8c92/skills/pptx/scripts/apply_theme.js');

const THEME = { name: 'DELTA-3', headFontFace: 'Cambria', bodyFontFace: 'Calibri',
  colors: { dk1: '13262E', lt1: 'FFFFFF', dk2: '0B3C49', lt2: 'EAF2F3', accent1: '1B998B', accent2: 'F2A541', accent3: 'E4572E', accent4: '2E86AB', accent5: '7FB7A7', accent6: '7A4B2A', hlink: '2E86AB', folHlink: '1B998B' } };
const HEX = THEME.colors;

const pres = new pptxgen();
pres.layout = 'LAYOUT_WIDE'; // 13.33 x 7.5
pres.theme = { headFontFace: THEME.headFontFace, bodyFontFace: THEME.bodyFontFace };
pres.title = 'DELTA-3 – Phát hiện sớm, Chặn tận gốc, Cảnh báo kịp thời';
const C = pres.SchemeColor;
const IMG = 'img/';
const OUT = process.argv[2] || 'DELTA-3_thuyet_trinh.pptx';
const FOOT = 'DELTA-3  ·  Phát hiện sớm – Chặn tận gốc – Cảnh báo kịp thời';

// ---------- layouts ----------
pres.defineSlideMaster({ title: 'TITLE_DARK', background: { color: HEX.dk2 },
  objects: [
    { placeholder: { options: { name: 'title', type: 'title', x: 0.7, y: 1.5, w: 7.2, h: 1.4, fontFace: THEME.headFontFace, fontSize: 60, bold: true, color: C.background1, valign: 'bottom', margin: 0 }, text: '' } },
    { placeholder: { options: { name: 'body', type: 'body', x: 0.7, y: 3.0, w: 7.2, h: 1.6, fontSize: 20, color: C.background2, valign: 'top', margin: 0 }, text: '' } },
  ] });
pres.defineSlideMaster({ title: 'SECTION', background: { color: HEX.dk2 },
  objects: [
    { placeholder: { options: { name: 'title', type: 'title', x: 0.9, y: 2.6, w: 8.0, h: 1.2, fontFace: THEME.headFontFace, fontSize: 44, bold: true, color: C.background1, valign: 'bottom', margin: 0 }, text: '' } },
    { placeholder: { options: { name: 'body', type: 'body', x: 0.9, y: 3.95, w: 8.0, h: 1.2, fontSize: 22, color: C.background2, valign: 'top', margin: 0 }, text: '' } },
  ], slideNumber: { x: 12.3, y: 7.0, w: 0.6, h: 0.3, fontSize: 11, color: 'BFD6DA' } });
pres.defineSlideMaster({ title: 'CONTENT', background: { color: HEX.lt1 },
  objects: [
    { placeholder: { options: { name: 'title', type: 'title', x: 0.6, y: 0.3, w: 12.1, h: 0.85, fontFace: THEME.headFontFace, fontSize: 32, bold: true, color: C.text2, valign: 'middle', margin: 0 }, text: '' } },
    { text: { text: FOOT, options: { x: 0.6, y: 7.02, w: 9, h: 0.3, fontSize: 10, color: '6B7F86', margin: 0 } } },
  ], slideNumber: { x: 12.3, y: 7.0, w: 0.6, h: 0.3, fontSize: 11, color: '6B7F86' } });

// ---------- helpers ----------
const SIZES = { 'tram_hop.png': [800, 605], 'tram_daunoi.png': [800, 495], 'hop_daunoi.png': [3200, 1800], 'app-screens.png': [1700, 840], 'diagram.png': [1500, 980],
  'v1c.png': [1000, 930], 'v2c.png': [1130, 880], 'v3c.png': [1140, 940], 'v4c.png': [1140, 1030], 'f38.jpg': [1280, 720], 'f50.jpg': [1280, 720], 'f70.jpg': [1280, 720], 'f94.jpg': [1280, 720], 'f20.jpg': [1280, 720] };
function pic(s, f, x, y, w, h, o = {}) { // fit inside box, centred
  const [pw, ph] = SIZES[f]; const k = Math.min(w / pw, h / ph); const iw = pw * k, ih = ph * k;
  s.addImage(Object.assign({ path: IMG + f, x: x + (w - iw) / 2, y: y + (h - ih) / 2, w: iw, h: ih, objectName: f }, o));
  return { x: x + (w - iw) / 2, y: y + (h - ih) / 2, w: iw, h: ih };
}
const iconCache = {};
async function icon(name, color) {
  const key = name + color; if (iconCache[key]) return iconCache[key];
  const svg = RDS.renderToStaticMarkup(React.createElement(fa[name], { color: '#' + color, size: 256 }));
  const buf = await sharp(Buffer.from(svg)).png().toBuffer();
  return (iconCache[key] = 'image/png;base64,' + buf.toString('base64'));
}
async function iconCircle(s, name, x, y, d, bg, fg) {
  s.addShape(pres.shapes.OVAL, { x, y, w: d, h: d, fill: { color: bg }, line: { color: bg }, objectName: 'iconbg' });
  s.addImage({ data: await icon(name, fg), x: x + d * 0.24, y: y + d * 0.24, w: d * 0.52, h: d * 0.52, objectName: 'icon-' + name });
}
const T = (s, text, o) => s.addText(text, Object.assign({ isTextBox: true, fontSize: 15, color: C.text1, valign: 'top', margin: 0 }, o));
const bullets = (items, o = {}) => items.map((t, i) => ({ text: t, options: Object.assign({ bullet: true, breakLine: i < items.length - 1, paraSpaceAfter: 6 }, o) }));
function card(s, x, y, w, h, fill = HEX.lt2) { s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h, rectRadius: 0.12, fill: { color: fill }, line: { color: fill }, objectName: 'card' }); }
function chip(s, text, x, y, w, color) { s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y, w, h: 0.38, rectRadius: 0.19, fill: { color }, line: { color } }); T(s, text, { x, y, w, h: 0.38, fontSize: 13, bold: true, color: C.background1, align: 'center', valign: 'middle' }); }

(async () => {
  let s;
  // ===== 1. Title =====
  pres.addSection({ title: 'Mở đầu' });
  s = pres.addSlide({ masterName: 'TITLE_DARK', sectionTitle: 'Mở đầu' });
  s.addText('DELTA-3', { placeholder: 'title' });
  s.addText([{ text: 'Phát hiện sớm – Chặn tận gốc – Cảnh báo kịp thời', options: { bold: true, color: HEX.accent2, breakLine: true } },
    { text: 'Hệ thống 3 lớp chống ô nhiễm nước và ngập đô thị, phát triển từ AquaSentinel AI', options: { fontSize: 18 } }], { placeholder: 'body' });
  T(s, [{ text: 'Nhóm tác giả: ', options: { bold: true } }, { text: 'Nguyễn Tấn Tường · Nguyễn Tấn Tuệ · Nguyễn Thị Tuyết Nhi · Đỗ Nguyễn Anh Thư · Nguyễn Thị Bích Phi', options: { breakLine: true } },
    { text: 'GV hướng dẫn: ', options: { bold: true } }, { text: 'Võ Phi Liên  ·  TP. Đà Nẵng  ·  2026' }], { x: 0.7, y: 5.3, w: 7.2, h: 1.0, fontSize: 14, color: C.background2 });
  pic(s, 'tram_hop.png', 8.5, 1.2, 4.3, 5.1, { rounding: false });
  T(s, 'Trạm quan trắc AquaSentinel đang chạy thử ngoài trời', { x: 8.5, y: 6.45, w: 4.3, h: 0.4, fontSize: 12, color: 'BFD6DA', italic: true, align: 'center' });
  s.addNotes('Giới thiệu tên đề tài DELTA-3: 3 lớp bảo vệ nối tiếp nhau theo thời gian của một cơn mưa. Nhấn mạnh đây là bản phát triển từ trạm quan trắc AquaSentinel AI nhóm đã làm và chạy thử.');

  // ===== 2. Problem =====
  s = pres.addSlide({ masterName: 'CONTENT', sectionTitle: 'Mở đầu' });
  s.addText('Ba vấn đề Đà Nẵng gặp mỗi mùa mưa', { placeholder: 'title' });
  const probs = [['FaIndustry', HEX.accent6, 'Xả thải lén', 'Thường xả ban đêm hoặc lúc mưa. Khi cơ quan chức năng đến kiểm tra, nước đã trong lại, khó có bằng chứng.'],
    ['FaCloudShowersHeavy', HEX.accent4, 'Nước mưa đợt đầu bẩn nhất', 'Rác, dầu nhớt, cặn bụi trên đường bị cuốn thẳng qua hố ga ra kênh, sông, biển. Rác còn làm tắc cống gây ngập.'],
    ['FaHouseFloodWater' in fa ? 'FaHouseFloodWater' : 'FaWater', HEX.accent3, 'Ngập nhanh và triều cường', 'Nước dâng trong vài chục phút. Người già, trẻ em, người đi đường không có app vẫn không biết đoạn nào nguy hiểm.']];
  for (let i = 0; i < 3; i++) { const x = 0.6 + i * 4.1, [ic, col, h, d] = probs[i];
    card(s, x, 1.45, 3.8, 3.9); await iconCircle(s, ic, x + 0.3, 1.75, 0.9, col, 'FFFFFF');
    T(s, h, { x: x + 0.3, y: 2.8, w: 3.3, h: 0.75, fontSize: 18, bold: true, color: C.text2 });
    T(s, d, { x: x + 0.3, y: 3.6, w: 3.3, h: 1.65, fontSize: 15 }); }
  card(s, 0.6, 5.65, 12.1, 1.05, HEX.dk2);
  T(s, [{ text: 'Thực tế: ', options: { bold: true, color: HEX.accent2 } }, { text: 'trận mưa lớn lịch sử ngày 14/10/2022 làm nhiều tuyến phố Đà Nẵng ngập sâu chỉ trong vài giờ. Các giải pháp hiện nay mới xử lý từng phần riêng lẻ.' }],
    { x: 0.9, y: 5.75, w: 11.5, h: 0.85, fontSize: 16, color: C.background1, valign: 'middle' });
  s.addNotes('Ba vấn đề này xảy ra trong cùng một cơn mưa nhưng ở 3 thời điểm khác nhau. Đó là lý do DELTA-3 có 3 lớp.');

  // ===== 3. Overview =====
  s = pres.addSlide({ masterName: 'CONTENT', sectionTitle: 'Mở đầu' });
  s.addText('DELTA-3: 3 lớp theo đúng diễn biến một cơn mưa', { placeholder: 'title' });
  const layers = [['TRƯỚC MƯA', 'Phát hiện sớm', 'Trạm quan trắc AquaSentinel nâng cấp', 'Đo 5 thông số + lượng mưa, AI tách "đục do mưa" và "xả thải lén", tự lấy mẫu làm bằng chứng', 'FaSatelliteDish', HEX.accent1],
    ['MƯA LỚN', 'Chặn tận gốc', 'Hố ga thụ động v4.1', 'Chặn rác, giữ nước bẩn đợt đầu, chống triều ngược, gom cát bùn. Không dùng điện, không mô-tơ', 'FaFilter', HEX.accent4],
    ['TRONG LŨ', 'Cảnh báo kịp thời', 'Hộp cứu hộ trên trụ điện', 'Đo độ sâu ngập, đèn tháp 3 màu + còi báo tại chỗ, nút SOS gửi vị trí. Chạy pin mặt trời', 'FaBell', HEX.accent3]];
  for (let i = 0; i < 3; i++) { const x = 0.6 + i * 4.1, [when, slogan, name, d, ic, col] = layers[i];
    card(s, x, 1.45, 3.8, 4.25); chip(s, when, x + 0.3, 1.7, 1.6, col);
    await iconCircle(s, ic, x + 2.75, 1.6, 0.75, col, 'FFFFFF');
    T(s, slogan, { x: x + 0.3, y: 2.45, w: 3.3, h: 0.55, fontSize: 22, bold: true, color: col, fontFace: THEME.headFontFace });
    T(s, name, { x: x + 0.3, y: 3.0, w: 3.3, h: 0.7, fontSize: 17, bold: true, color: C.text2 });
    T(s, d, { x: x + 0.3, y: 3.75, w: 3.3, h: 1.8, fontSize: 15 });
    if (i < 2) s.addShape(pres.shapes.RIGHT_ARROW, { x: x + 3.82, y: 3.3, w: 0.26, h: 0.45, fill: { color: HEX.accent2 }, line: { color: HEX.accent2 } }); }
  card(s, 0.6, 5.95, 12.1, 0.8, HEX.dk2);
  T(s, [{ text: 'Kết nối chung: ', options: { bold: true, color: HEX.accent2 } }, { text: 'LoRa 923 MHz → máy chủ AI → App Flutter cho người dân + Web cho cơ quan quản lý. LoRa vẫn chạy khi mất điện, mất sóng 4G.' }],
    { x: 0.9, y: 6.0, w: 11.5, h: 0.7, fontSize: 15, color: C.background1, valign: 'middle' });
  s.addNotes('Tên DELTA-3: Delta là sự thay đổi, cũng gợi vùng cửa sông nơi nước mưa đổ ra biển. Số 3 là 3 lớp. Mỗi lớp làm được việc riêng, ghép lại thì bao trọn trước, trong và sau mưa.');

  // ===== 4. Section 1 =====
  pres.addSection({ title: 'Lớp 1 – Trạm quan trắc' });
  s = pres.addSlide({ masterName: 'SECTION', sectionTitle: 'Lớp 1 – Trạm quan trắc' });
  s.addText('Lớp 1 · Phát hiện sớm', { placeholder: 'title' });
  s.addText('Trạm quan trắc AquaSentinel – bản nâng cấp có vũ lượng kế', { placeholder: 'body' });
  await iconCircle(s, 'FaSatelliteDish', 10.0, 2.4, 2.2, HEX.accent1, 'FFFFFF');

  // ===== 5. Station =====
  s = pres.addSlide({ masterName: 'CONTENT', sectionTitle: 'Lớp 1 – Trạm quan trắc' });
  s.addText('Trạm quan trắc: đo liên tục, giữ bằng chứng', { placeholder: 'title' });
  pic(s, 'tram_hop.png', 0.6, 1.4, 5.2, 5.3);
  T(s, 'Đã có (bản AquaSentinel AI)', { x: 6.2, y: 1.4, w: 6.5, h: 0.45, fontSize: 20, bold: true, color: C.text2 });
  T(s, bullets(['Đo thời gian thực: nhiệt độ (DS18B20), TDS, độ đục (TH204), lưu lượng (YF-S201), mực nước (JSN-SR04T)',
    'Vượt ngưỡng thì bơm 12V tự lấy mẫu nước làm bằng chứng',
    'Buồng đo inox 304 đục lỗ + tấm đồng chống rêu bám, rẻ hơn hệ làm sạch siêu âm',
    '2 ESP32: trạm đo phát LoRa, trạm nhận đẩy MQTT lên máy chủ']), { x: 6.2, y: 1.9, w: 6.5, h: 2.5, fontSize: 15 });
  card(s, 6.2, 4.55, 6.5, 2.15, 'FFF4E0');
  await iconCircle(s, 'FaCloudRain', 6.45, 4.8, 0.75, HEX.accent2, 'FFFFFF');
  T(s, 'Nâng cấp mới', { x: 7.4, y: 4.75, w: 5.1, h: 0.4, fontSize: 18, bold: true, color: HEX.accent6 });
  T(s, bullets(['Vũ lượng kế kiểu gầu lật: đo lượng mưa ngay tại trạm',
    'AI biết lúc nào đang mưa, nên nước đục do mưa không bị báo nhầm là xả thải',
    'Dùng được cả mùa khô và mùa mưa']), { x: 7.4, y: 5.2, w: 5.1, h: 1.45, fontSize: 14 });
  s.addNotes('Giữ nguyên phần cứng đã chạy thử. Điểm nâng cấp quan trọng nhất là vũ lượng kế: không có nó, mùa mưa trạm sẽ báo động giả liên tục vì nước đục lên.');

  // ===== 6. Station wiring =====
  s = pres.addSlide({ masterName: 'CONTENT', sectionTitle: 'Lớp 1 – Trạm quan trắc' });
  s.addText('Sơ đồ đấu nối trạm quan trắc', { placeholder: 'title' });
  const r6 = pic(s, 'tram_daunoi.png', 0.6, 1.35, 8.6, 5.4);
  s.addShape(pres.shapes.RECTANGLE, { x: r6.x, y: r6.y, w: r6.w, h: r6.h, fill: { type: 'none' }, line: { color: 'C9D6DA', width: 1 } });
  card(s, 9.5, 1.35, 3.2, 5.4);
  T(s, 'Khối chính', { x: 9.75, y: 1.55, w: 2.8, h: 0.4, fontSize: 17, bold: true, color: C.text2 });
  T(s, bullets(['ESP32 xử lý trung tâm', 'LoRa Ra-02 truyền xa', '2 nguồn pin: mạch + bơm', 'Relay bật bơm 12V lấy mẫu', '5 cảm biến môi trường']), { x: 9.75, y: 2.0, w: 2.8, h: 2.3, fontSize: 14 });
  T(s, 'Thêm vũ lượng kế', { x: 9.75, y: 4.35, w: 2.8, h: 0.4, fontSize: 17, bold: true, color: HEX.accent6 });
  T(s, 'Công tắc lưỡi gà 2 dây: 1 dây vào chân GPIO có ngắt (bật kéo lên trong), 1 dây vào GND. Mỗi lần gầu lật là 1 xung, hiệu chuẩn bằng ống đong.', { x: 9.75, y: 4.8, w: 2.8, h: 1.8, fontSize: 13 });
  s.addNotes('Trình bày theo dòng: nguồn → hạ áp → ESP32 → cảm biến; ESP32 → relay → bơm; ESP32 → LoRa. Vũ lượng kế chỉ cần thêm 2 dây, không phải sửa mạch cũ.');

  // ===== 7. AI + app =====
  s = pres.addSlide({ masterName: 'CONTENT', sectionTitle: 'Lớp 1 – Trạm quan trắc' });
  s.addText('AI tách mưa và xả thải, App + Web cho mọi người', { placeholder: 'title' });
  pic(s, 'app-screens.png', 0.6, 1.35, 7.4, 3.7);
  const ai = [['Đang mưa + mực nước dâng + đục tăng + TDS loãng ra', '→ nước mưa chảy tràn, không báo động', HEX.accent4],
    ['Không mưa + TDS tăng vọt, thường vào ban đêm', '→ nghi xả thải lén: báo động + bơm lấy mẫu', HEX.accent3]];
  for (let i = 0; i < 2; i++) { const y = 1.35 + i * 1.9; card(s, 8.3, y, 4.4, 1.7);
    T(s, ai[i][0], { x: 8.55, y: y + 0.15, w: 3.95, h: 0.8, fontSize: 15, bold: true, color: C.text2 });
    T(s, ai[i][1], { x: 8.55, y: y + 0.95, w: 3.95, h: 0.65, fontSize: 15, bold: true, color: ai[i][2] }); }
  T(s, bullets(['Người dân: xem bản đồ, nhận cảnh báo, gửi ảnh phản ánh có vị trí GPS', 'Cơ quan quản lý: tiếp nhận phản ánh, xem dữ liệu và mẫu nước bằng chứng trên Web', 'Song ngữ Việt/Anh, chế độ sáng/tối']),
    { x: 0.6, y: 5.3, w: 12.1, h: 1.5, fontSize: 15 });
  s.addNotes('Đây là lý do vũ lượng kế quan trọng: AI cần biết có mưa hay không để không báo nhầm.');

  // ===== 8. Section 2 =====
  pres.addSection({ title: 'Lớp 2 – Hố ga thụ động' });
  s = pres.addSlide({ masterName: 'SECTION', sectionTitle: 'Lớp 2 – Hố ga thụ động' });
  s.addText('Lớp 2 · Chặn tận gốc', { placeholder: 'title' });
  s.addText('Hố ga thụ động – 5 bước nghiên cứu, từ van Tesla tới v4.1', { placeholder: 'body' });
  await iconCircle(s, 'FaFilter', 10.0, 2.4, 2.2, HEX.accent4, 'FFFFFF');

  // ===== 9. Research timeline =====
  s = pres.addSlide({ masterName: 'CONTENT', sectionTitle: 'Lớp 2 – Hố ga thụ động' });
  s.addText('Hành trình nghiên cứu: mỗi bản sửa 1 điểm yếu', { placeholder: 'title' });
  const tl = [['v1', 'Ý tưởng', 'Lưới Coanda + bóng phao giữ nước đợt đầu + van Tesla chống triều', 'Chưa có kích thước thật'],
    ['v2', 'Kích thước thật', 'Hố ga 1200×1000, ống trữ HDPE D600 0,85 m³, tính thủy lực, chi phí', 'Van Tesla vẫn rò ngược, dễ tắc'],
    ['v3', 'Bỏ van Tesla', 'Van mỏ vịt EPDM + cửa lật composite nối tiếp, lưới Coanda bảo vệ van', '2 van nối tiếp làm chậm thoát nước'],
    ['v4', 'Tách 2 đường', 'Đường A: van mỏ vịt. Đường B: cửa tràn cao + cửa lật. Ống đo triều', 'Cát bùn lọt lưới đọng đáy hố'],
    ['v4.1', 'Hố lắng bùn', 'Hố lắng Ø400 ở tâm đáy, xô inox nhấc lên. Video mô phỏng đầy đủ', 'Bản hoàn thiện']];
  s.addShape(pres.shapes.LINE, { x: 0.9, y: 2.05, w: 11.5, h: 0, line: { color: HEX.accent5, width: 3 } });
  for (let i = 0; i < 5; i++) { const x = 0.6 + i * 2.45, last = i === 4, col = last ? HEX.accent2 : HEX.accent4;
    s.addShape(pres.shapes.OVAL, { x: x + 0.55, y: 1.55, w: 1.0, h: 1.0, fill: { color: col }, line: { color: 'FFFFFF', width: 3 } });
    T(s, tl[i][0], { x: x + 0.55, y: 1.55, w: 1.0, h: 1.0, fontSize: last ? 18 : 20, bold: true, color: C.background1, align: 'center', valign: 'middle' });
    card(s, x, 2.8, 2.15, 3.95, last ? 'FFF4E0' : HEX.lt2);
    T(s, tl[i][1], { x: x + 0.18, y: 2.95, w: 1.8, h: 0.5, fontSize: 17, bold: true, color: C.text2 });
    T(s, tl[i][2], { x: x + 0.18, y: 3.45, w: 1.8, h: 2.2, fontSize: 14 });
    T(s, [{ text: last ? '✓ ' : 'Còn vướng: ', options: { bold: true } }, { text: tl[i][3] }], { x: x + 0.18, y: 5.65, w: 1.8, h: 1.0, fontSize: 13, color: last ? HEX.accent1 : HEX.accent3 }); }
  s.addNotes('Giám khảo đánh giá cao quá trình: nhóm không giữ ý tưởng ban đầu mà tự tìm điểm yếu và sửa qua từng phiên bản.');

  // ===== 10. v1-v2 Tesla =====
  s = pres.addSlide({ masterName: 'CONTENT', sectionTitle: 'Lớp 2 – Hố ga thụ động' });
  s.addText('v1 – v2: thử van Tesla để chống triều ngược', { placeholder: 'title' });
  pic(s, 'v1c.png', 0.6, 1.4, 3.9, 3.7); pic(s, 'v2c.png', 4.7, 1.4, 4.4, 3.7);
  T(s, 'v1: bản ý tưởng', { x: 0.6, y: 5.15, w: 3.9, h: 0.35, fontSize: 13, italic: true, color: '6B7F86', align: 'center' });
  T(s, 'v2: kích thước thật, van Tesla D300', { x: 4.7, y: 5.15, w: 4.4, h: 0.35, fontSize: 13, italic: true, color: '6B7F86', align: 'center' });
  card(s, 9.4, 1.4, 3.3, 5.3);
  T(s, 'Vì sao thử', { x: 9.65, y: 1.6, w: 2.9, h: 0.4, fontSize: 17, bold: true, color: C.text2 });
  T(s, 'Van Tesla không có bộ phận chuyển động: dòng xuôi đi thẳng, dòng ngược bị các nhánh vòng cản lại.', { x: 9.65, y: 2.05, w: 2.9, h: 1.5, fontSize: 14 });
  T(s, 'Phát hiện', { x: 9.65, y: 3.6, w: 2.9, h: 0.4, fontSize: 17, bold: true, color: HEX.accent3 });
  T(s, bullets(['Chỉ cản bớt, vẫn rò ngược, không đóng kín', 'Kênh hẹp dễ tắc rác', 'Khó và đắt khi làm cỡ D300']), { x: 9.65, y: 4.05, w: 2.9, h: 1.6, fontSize: 14 });
  T(s, '→ Bỏ làm van chính, giữ lại để so sánh trong thí nghiệm', { x: 9.65, y: 5.7, w: 2.9, h: 0.9, fontSize: 14, bold: true, color: HEX.accent1 });
  s.addNotes('Nói rõ: van Tesla rất hay về mặt ý tưởng nhưng chống triều cần đóng kín, nên nhóm chuyển sang van một chiều thật sự.');

  // ===== 11. v3 =====
  s = pres.addSlide({ masterName: 'CONTENT', sectionTitle: 'Lớp 2 – Hố ga thụ động' });
  s.addText('v3: van mỏ vịt + cửa lật, có lưới Coanda bảo vệ', { placeholder: 'title' });
  pic(s, 'v3c.png', 0.6, 1.4, 6.6, 5.3);
  const v3 = [['Lưới Coanda inox khe 1 mm', 'Nước lọt khe, rác tự trượt xuống giỏ. Van phía sau không bị kẹt rác'],
    ['Van mỏ vịt cao su EPDM', 'Không bản lề, tự khép khi nước đẩy ngược'],
    ['Cửa lật composite', 'Lớp chặn thứ 2, nối tiếp sau van mỏ vịt']];
  for (let i = 0; i < 3; i++) { const y = 1.4 + i * 1.3; card(s, 7.5, y, 5.2, 1.15);
    T(s, v3[i][0], { x: 7.75, y: y + 0.12, w: 4.8, h: 0.4, fontSize: 16, bold: true, color: C.text2 });
    T(s, v3[i][1], { x: 7.75, y: y + 0.52, w: 4.8, h: 0.6, fontSize: 14 }); }
  card(s, 7.5, 5.35, 5.2, 1.35, 'FDE8E2');
  T(s, [{ text: 'Còn vướng: ', options: { bold: true, color: HEX.accent3 } }, { text: '2 van nối tiếp trên 1 ống, tổn thất cộng dồn. Mưa cực lớn nước thoát chậm hơn hố ga thường → phải sửa.' }], { x: 7.75, y: 5.45, w: 4.8, h: 1.15, fontSize: 14, valign: 'middle' });

  // ===== 12. v4 =====
  s = pres.addSlide({ masterName: 'CONTENT', sectionTitle: 'Lớp 2 – Hố ga thụ động' });
  s.addText('v4: tách dòng thành 2 đường thoát nước', { placeholder: 'title' });
  pic(s, 'v4c.png', 0.6, 1.4, 6.2, 5.3);
  chip(s, 'ĐƯỜNG A · mưa thường', 7.1, 1.45, 2.8, HEX.accent1);
  T(s, 'Lưới Coanda → hố thu → van mỏ vịt D300 → cống chính. Nước đã lọc rác nên van không kẹt.', { x: 7.1, y: 1.95, w: 5.6, h: 0.9, fontSize: 15 });
  chip(s, 'ĐƯỜNG B · mưa cực lớn', 7.1, 2.95, 2.8, HEX.accent4);
  T(s, 'Cửa tràn đặt cao hơn ống ra 300 mm, nước dâng tới mới chảy, xả thẳng qua cửa lật nhẹ, khoảng 100 L/s. Độ cao thay đối trọng: rẻ, không phải chỉnh.', { x: 7.1, y: 3.45, w: 5.6, h: 1.2, fontSize: 15 });
  chip(s, 'TRIỀU CƯỜNG', 7.1, 4.75, 2.8, HEX.accent3);
  T(s, 'Cả 2 đường đều một chiều. Ống đo triều Ø21 kiểu bình thông nhau nâng công tắc phao → LoRa báo hộp cứu hộ chuyển vàng sớm.', { x: 7.1, y: 5.25, w: 5.6, h: 1.2, fontSize: 15 });

  // ===== 13. v4.1 video =====
  s = pres.addSlide({ masterName: 'CONTENT', sectionTitle: 'Lớp 2 – Hố ga thụ động' });
  s.addText('v4.1: hố lắng bùn + video mô phỏng toàn bộ', { placeholder: 'title' });
  const cov = 'image/jpeg;base64,' + fs.readFileSync('vcover.jpg').toString('base64');
  s.addMedia({ type: 'video', path: 'hoga_mophong.mp4', x: 0.6, y: 1.4, w: 8.0, h: 4.5, cover: cov, objectName: 'video-hoga-v41' });
  T(s, 'Bấm vào video để phát (1 phút 48 giây). 7 giai đoạn: trời khô → mưa đầu → bể đầy → mưa cực lớn → tạnh mưa → triều cường → bảo trì', { x: 0.6, y: 6.0, w: 8.0, h: 0.75, fontSize: 13, italic: true, color: '6B7F86' });
  card(s, 8.9, 1.4, 3.8, 5.3, 'FFF4E0');
  await iconCircle(s, 'FaRecycle', 9.15, 1.6, 0.75, HEX.accent2, 'FFFFFF');
  T(s, 'Hố lắng bùn ở tâm đáy', { x: 10.05, y: 1.65, w: 2.5, h: 0.7, fontSize: 17, bold: true, color: HEX.accent6, valign: 'middle' });
  T(s, bullets(['Đáy dốc 5% về tâm, hố Ø400 sâu 300 (~38 lít)', 'Xô inox đục lỗ: mở nắp gang, móc quai nhấc lên, không phải xuống hố',
    'Đáy ống ra cao hơn đáy 200 mm để cát kịp chìm', 'Cát 0,2 mm chìm 20–25 mm/s, nhanh hơn nước dâng (~9 mm/s) nên lắng được']), { x: 9.15, y: 2.55, w: 3.35, h: 4.0, fontSize: 14 });
  s.addNotes('Phát video. Dừng ở giai đoạn 3 để chỉ cát lắng về hố, giai đoạn 4 để chỉ đường B mở, giai đoạn 6 để chỉ triều bị chặn cả 2 đường, giai đoạn 7 nhấc giỏ rác và xô cát.');

  // ===== 14. numbers =====
  s = pres.addSlide({ masterName: 'CONTENT', sectionTitle: 'Lớp 2 – Hố ga thụ động' });
  s.addText('Hố ga v4.1 qua con số (1 hố ga, khoảng cách 30 m)', { placeholder: 'title' });
  const stats = [['0,85 m³', 'nước bẩn đợt đầu giữ lại mỗi hố, xả chậm về nhà máy xử lý', HEX.accent6],
    ['~10 lần', 'công suất lưới Coanda (90–135 L/s) so với lưu lượng đỉnh 7,5–11 L/s', HEX.accent1],
    ['~100 L/s', 'khả năng thoát dự phòng của đường B khi mưa cực lớn', HEX.accent4],
    ['0 điện', 'không mô-tơ, không bơm: vẫn chạy khi mất điện trong bão', HEX.accent3]];
  for (let i = 0; i < 4; i++) { const x = 0.6 + i * 3.08; card(s, x, 1.45, 2.85, 3.0);
    T(s, stats[i][0], { x: x + 0.2, y: 1.65, w: 2.45, h: 1.0, fontSize: 34, bold: true, color: stats[i][2], fontFace: THEME.headFontFace, valign: 'middle' });
    T(s, stats[i][1], { x: x + 0.2, y: 2.75, w: 2.45, h: 1.6, fontSize: 14 }); }
  T(s, 'Chi phí ước tính 1 hố ga (triệu đồng)', { x: 0.6, y: 4.7, w: 6, h: 0.4, fontSize: 17, bold: true, color: C.text2 });
  s.addTable([[{ text: 'Phương án', options: { bold: true, color: 'FFFFFF', fill: { color: HEX.dk2 } } }, { text: 'Gồm', options: { bold: true, color: 'FFFFFF', fill: { color: HEX.dk2 } } }, { text: 'Chi phí', options: { bold: true, color: 'FFFFFF', fill: { color: HEX.dk2 }, align: 'right' } }],
    ['Tối thiểu', 'Module lưới Coanda + giỏ rác', { text: '12–18', options: { align: 'right' } }],
    [{ text: 'Lắp vào hố ga có sẵn', options: { bold: true } }, 'Lưới, giỏ, van mỏ vịt, đường B, hố lắng, cảm biến (không đào vỉa hè)', { text: '23–40', options: { align: 'right', bold: true } }],
    ['Đầy đủ', 'Thêm ống trữ HDPE D600 giữ nước đợt đầu', { text: '36–60', options: { align: 'right' } }]],
    { x: 0.6, y: 5.1, w: 12.1, colW: [2.6, 7.9, 1.6], fontSize: 14, color: HEX.dk1, border: { type: 'solid', color: 'D5E2E5', pt: 1 }, rowH: 0.36 });
  s.addNotes('Giá là ước tính, khoảng rộng chủ yếu vì van mỏ vịt D300 chưa có báo giá. Phương án lắp vào hố ga có sẵn là dễ áp dụng nhất.');

  // ===== 15. Section 3 =====
  pres.addSection({ title: 'Lớp 3 – Hộp cứu hộ' });
  s = pres.addSlide({ masterName: 'SECTION', sectionTitle: 'Lớp 3 – Hộp cứu hộ' });
  s.addText('Lớp 3 · Cảnh báo kịp thời', { placeholder: 'title' });
  s.addText('Hộp cứu hộ trên trụ điện: đèn tháp 3 màu, còi, nút SOS', { placeholder: 'body' });
  await iconCircle(s, 'FaBell', 10.0, 2.4, 2.2, HEX.accent3, 'FFFFFF');

  // ===== 16. Beacon function =====
  s = pres.addSlide({ masterName: 'CONTENT', sectionTitle: 'Lớp 3 – Hộp cứu hộ' });
  s.addText('Ai đi ngang cũng hiểu, không cần điện thoại', { placeholder: 'title' });
  const lv = [['22C55E', 'AN TOÀN', 'Xanh chớp 0,1 s mỗi 5 s', 'Tắt'], ['F2A541', 'CHÚ Ý · ≥ 10 cm', 'Vàng nháy 1 Hz', 'Bíp dồn 10 s, rồi 1 bíp / 2 phút'],
    ['E4572E', 'NGUY HIỂM · ≥ 30 cm', 'Đỏ nháy 2 Hz', 'Kêu dồn 10 s, rồi 3 bíp / 30 s'], ['2E86AB', 'VỪA BẤM SOS', '3 màu chạy vòng 30 s', 'Bíp ngắn mỗi 2 s']];
  for (let i = 0; i < 4; i++) { const y = 1.4 + i * 1.33; card(s, 0.6, y, 6.6, 1.18);
    s.addShape(pres.shapes.OVAL, { x: 0.85, y: y + 0.24, w: 0.7, h: 0.7, fill: { color: lv[i][0] }, line: { color: lv[i][0] } });
    T(s, lv[i][1], { x: 1.8, y: y + 0.12, w: 5.2, h: 0.4, fontSize: 16, bold: true, color: C.text2 });
    T(s, [{ text: 'Đèn: ', options: { bold: true } }, { text: lv[i][2] + '    ' }, { text: 'Còi: ', options: { bold: true } }, { text: lv[i][3] }], { x: 1.8, y: y + 0.55, w: 5.3, h: 0.55, fontSize: 14 }); }
  const bf = [['FaRulerVertical', 'Mỗi hộp là 1 điểm đo ngập', 'Siêu âm chống nước chĩa xuống mặt đường'], ['FaEye', 'Thấy từ 50–100 m', 'Đèn tháp IP65 của nhà xưởng, thấy cả khi mưa'],
    ['FaMapMarkerAlt', 'SOS có vị trí', 'Gửi vị trí + độ sâu nước thật về trung tâm cứu hộ'], ['FaSolarPanel', '8–10 ngày không nắng', 'Pin LiFePO4 12,8V 6Ah + tấm pin 10W, LoRa không cần 4G']];
  for (let i = 0; i < 4; i++) { const y = 1.4 + i * 1.33; await iconCircle(s, bf[i][0], 7.6, y + 0.15, 0.8, HEX.dk2, 'FFFFFF');
    T(s, bf[i][1], { x: 8.6, y: y + 0.1, w: 4.1, h: 0.4, fontSize: 16, bold: true, color: C.text2 });
    T(s, bf[i][2], { x: 8.6, y: y + 0.5, w: 4.1, h: 0.65, fontSize: 14 }); }
  s.addNotes('Nhóm đã thay tấm LED chạy chữ bằng đèn tháp 3 màu: bền ngoài trời hơn, nhìn xa hơn, ít tốn điện hơn (~0,3–0,4 W trung bình) và ai cũng hiểu màu xanh, vàng, đỏ.');

  // ===== 17. Beacon wiring =====
  s = pres.addSlide({ masterName: 'CONTENT', sectionTitle: 'Lớp 3 – Hộp cứu hộ' });
  s.addText('Sơ đồ đấu nối hộp cứu hộ', { placeholder: 'title' });
  const r17 = pic(s, 'hop_daunoi.png', 0.6, 1.3, 12.1, 5.55);
  s.addShape(pres.shapes.RECTANGLE, { x: r17.x, y: r17.y, w: r17.w, h: r17.h, fill: { type: 'none' }, line: { color: 'C9D6DA', width: 1 } });
  s.addNotes('Nguồn: tấm pin → bộ sạc → pin LiFePO4 → cầu chì 2A → BUS 12V. BUS 12V nuôi dây chung của đèn tháp và hạ áp xuống 5V cho ESP32. ESP32 điều khiển 4 kênh ULN2003 kéo từng màu và còi xuống GND. Siêu âm JSN-SR04T có chia áp chân ECHO. LoRa nối SPI.');

  // ===== 18. Beacon BOM =====
  s = pres.addSlide({ masterName: 'CONTENT', sectionTitle: 'Lớp 3 – Hộp cứu hộ' });
  s.addText('Linh kiện 1 hộp cứu hộ: khoảng 1,9–2,7 triệu đồng', { placeholder: 'title' });
  const H = (t, a) => ({ text: t, options: { bold: true, color: 'FFFFFF', fill: { color: HEX.dk2 }, align: a || 'left' } });
  const bom = [[H('Nhóm'), H('Linh kiện'), H('Giá (nghìn đ)', 'right')],
    ['Xử lý & truyền', 'ESP32 DevKit V1; LoRa SX1276 Ra-01H 923 MHz + anten', { text: '270–390', options: { align: 'right' } }],
    ['Cảnh báo', 'Đèn tháp LED 3 màu có còi 12VDC, chung dương, IP65', { text: '150–350', options: { align: 'right' } }],
    ['Đo ngập & SOS', 'Siêu âm chống nước JSN-SR04T; nút nhấn IP67 Ø16', { text: '120–200', options: { align: 'right' } }],
    ['Điều khiển', 'ULN2003; hạ áp 12V→5V MP1584; điện trở chia áp', { text: '32–67', options: { align: 'right' } }],
    ['Nguồn', 'Pin LiFePO4 12,8V 6Ah; tấm pin 10W 18V; bộ sạc solar 10A', { text: '770–1.220', options: { align: 'right' } }],
    ['Bảo vệ', 'Cầu chì 2A, TVS SMBJ24A, tụ lọc; sơn phủ mạch, hút ẩm', { text: '80–130', options: { align: 'right' } }],
    ['Vỏ & lắp đặt', 'Hộp IP65, ốc siết cáp, nút thông hơi, đai inox ôm cột, mái che', { text: '265–430', options: { align: 'right' } }],
    [{ text: 'Tổng', options: { bold: true } }, { text: 'Bản demo trên bàn (không pin lớn, không tấm pin): ~1,1–1,4 triệu', options: { italic: true } }, { text: '~1.900–2.700', options: { align: 'right', bold: true } }]];
  s.addTable(bom, { x: 0.6, y: 1.4, w: 12.1, colW: [2.3, 7.6, 2.2], fontSize: 14, color: HEX.dk1, border: { type: 'solid', color: 'D5E2E5', pt: 1 }, rowH: 0.52, fill: { color: 'FFFFFF' } });
  T(s, 'Lưu ý khi mua đèn tháp: đúng loại 12VDC (không phải 24V/220V), có còi tích hợp, dây chung là dương. Giá tham khảo, cần lấy báo giá thật.', { x: 0.6, y: 6.25, w: 12.1, h: 0.6, fontSize: 13, italic: true, color: '6B7F86' });

  // ===== 19. Innovation =====
  pres.addSection({ title: 'Sáng tạo – Giá thành – Áp dụng' });
  s = pres.addSlide({ masterName: 'CONTENT', sectionTitle: 'Sáng tạo – Giá thành – Áp dụng' });
  s.addText('Điểm sáng tạo và mới so với cách làm hiện nay', { placeholder: 'title' });
  const cmp = [[H('Lớp'), H('Cách làm hiện nay'), H('DELTA-3')],
    [{ text: 'Phát hiện', options: { bold: true } }, 'Trạm quan trắc tự động thương mại giá cao nên ít điểm đo; kiểm tra thủ công thường đến muộn', 'Trạm giá thấp, tự lấy mẫu làm bằng chứng; vũ lượng kế + AI tách nước mưa và xả thải lén'],
    [{ text: 'Xử lý', options: { bold: true } }, 'Hố ga hàm ếch chỉ có song chắn rác thô; nước đợt đầu và rác chảy thẳng ra kênh, biển', 'Lưới Coanda tự làm sạch + giữ nước đợt đầu + 2 đường một chiều + hố lắng bùn, không dùng điện'],
    [{ text: 'Cảnh báo', options: { bold: true } }, 'Qua tin nhắn, app, loa: cần điện thoại, cần sóng 4G, cần điện lưới', 'Đèn + còi ngay tại điểm ngập, SOS có vị trí, chạy pin mặt trời và LoRa khi mất điện, mất sóng']];
  s.addTable(cmp, { x: 0.6, y: 1.4, w: 12.1, colW: [1.7, 4.9, 5.5], fontSize: 15, color: HEX.dk1, border: { type: 'solid', color: 'D5E2E5', pt: 1 }, rowH: [0.5, 1.05, 1.05, 1.05], valign: 'middle' });
  card(s, 0.6, 5.35, 12.1, 1.35, 'FFF4E0');
  await iconCircle(s, 'FaLightbulb', 0.85, 5.55, 0.9, HEX.accent2, 'FFFFFF');
  T(s, [{ text: 'Cái mới lớn nhất: ', options: { bold: true, color: HEX.accent6 } }, { text: 'ghép 3 lớp vào một hệ thống theo đúng diễn biến cơn mưa. Trạm và hố ga báo trước cho hộp cứu hộ, hộp cứu hộ báo người dân ngay tại chỗ, tất cả dùng chung LoRa và máy chủ AI.' }],
    { x: 2.0, y: 5.45, w: 10.5, h: 1.15, fontSize: 15, valign: 'middle' });
  s.addNotes('Nói đúng mức: từng bộ phận (lưới Coanda, van mỏ vịt, đèn tháp) đã có trên thị trường. Điểm mới là cách tích hợp cho hố ga hàm ếch và cho bài toán Đà Nẵng. Không nói "chưa từng có".');

  // ===== 20. Cost chart =====
  s = pres.addSlide({ masterName: 'CONTENT', sectionTitle: 'Sáng tạo – Giá thành – Áp dụng' });
  s.addText('Giá thành: làm dần được, bắt đầu từ vài triệu đồng', { placeholder: 'title' });
  s.addChart(pres.charts.BAR, [{ name: 'Thấp nhất', labels: ['Hộp cứu hộ', 'Mô hình demo hố ga 1:5', 'Hố ga – tối thiểu', 'Hố ga – lắp vào hố có sẵn', 'Hố ga – đầy đủ'], values: [1.9, 1.5, 12, 23, 36] },
    { name: 'Cao nhất', labels: ['Hộp cứu hộ', 'Mô hình demo hố ga 1:5', 'Hố ga – tối thiểu', 'Hố ga – lắp vào hố có sẵn', 'Hố ga – đầy đủ'], values: [2.7, 2, 18, 40, 60] }],
    { x: 0.6, y: 1.35, w: 7.6, h: 5.4, barDir: 'bar', barGrouping: 'clustered', chartColors: [HEX.accent1, HEX.accent2], showTitle: true, title: 'Chi phí ước tính (triệu đồng)', titleFontSize: 14, titleColor: HEX.dk1, titleFontFace: '+mn-lt',
      showValue: true, dataLabelPosition: 'outEnd', dataLabelFontSize: 12, dataLabelColor: HEX.dk1, dataLabelFontFace: '+mn-lt', showLegend: true, legendPos: 'b', legendFontSize: 12, legendFontFace: '+mn-lt',
      catAxisLabelColor: '44545A', valAxisLabelColor: '44545A', catAxisLabelFontSize: 12, valAxisLabelFontSize: 11, catAxisLabelFontFace: '+mn-lt', valAxisLabelFontFace: '+mn-lt', valGridLine: { color: 'E1E9EB', size: 1 }, catGridLine: { style: 'none' }, valAxisMaxVal: 70 });
  card(s, 8.5, 1.35, 4.2, 5.4);
  T(s, 'Vì sao rẻ', { x: 8.75, y: 1.55, w: 3.8, h: 0.4, fontSize: 18, bold: true, color: C.text2 });
  T(s, bullets(['Linh kiện phổ biến, mua được trong nước (ESP32, LoRa, cảm biến)', 'Hố ga lắp vào hố có sẵn, không phải đào đường làm lại', 'Không điện, không mô-tơ nên gần như không tốn vận hành', 'Làm từng lớp: thành phố chọn lớp cần nhất cho từng điểm']), { x: 8.75, y: 2.05, w: 3.8, h: 3.3, fontSize: 14 });
  T(s, 'Số liệu ước tính, cần báo giá thật trước khi thi công.', { x: 8.75, y: 5.9, w: 3.8, h: 0.7, fontSize: 12, italic: true, color: '6B7F86' });

  // ===== 20b. Feasibility =====
  s = pres.addSlide({ masterName: 'CONTENT', sectionTitle: 'Sáng tạo – Giá thành – Áp dụng' });
  s.addText('Tính khả thi: rủi ro nào cũng đã có cách xử lý', { placeholder: 'title' });
  const rk = [['Mùa mưa nước đục, dễ báo động giả', 'Vũ lượng kế + AI phân loại theo lượng mưa, mực nước, TDS'],
    ['Rác làm kẹt van chống triều', 'Lưới Coanda tự làm sạch lọc trước; van mỏ vịt không bản lề'],
    ['Mưa vượt thiết kế gây ngập', 'Đường B tràn tự do ~100 L/s; tràn qua mép lưới về giỏ, không kém hố ga thường'],
    ['Bão làm mất điện, mất sóng 4G', 'Pin LiFePO4 + tấm pin 10 W; LoRa không phụ thuộc mạng di động'],
    ['Bảo trì tốn công', 'Module rút lên qua nắp gang, xô hố lắng nhấc ra, cảm biến báo giỏ đầy qua LoRa'],
    ['Chi phí và thi công', 'Lắp vào hố ga có sẵn, không đào đường; làm dần từng lớp, từng điểm']];
  s.addTable([[H('Rủi ro'), H('Cách DELTA-3 xử lý')], ...rk.map(r => [{ text: r[0], options: { bold: true } }, r[1]])],
    { x: 0.6, y: 1.4, w: 7.9, colW: [3.0, 4.9], fontSize: 14, color: HEX.dk1, border: { type: 'solid', color: 'D5E2E5', pt: 1 }, rowH: 0.74, valign: 'middle' });
  card(s, 8.8, 1.4, 3.9, 5.3, HEX.dk2);
  T(s, 'Đã chứng minh được', { x: 9.05, y: 1.6, w: 3.4, h: 0.45, fontSize: 18, bold: true, color: HEX.accent2 });
  T(s, bullets(['Trạm quan trắc đã lắp và chạy thử ngoài trời, truyền LoRa + MQTT lên App/Web', 'Toàn bộ nguyên lý hố ga là cơ khí đã được dùng trong ngành thoát nước: hiệu ứng Coanda, van một chiều, bình thông nhau, lắng trọng lực', 'Linh kiện mua được trong nước'], { color: 'FFFFFF' }),
    { x: 9.05, y: 2.15, w: 3.4, h: 3.2, fontSize: 14, color: C.background1 });
  T(s, 'Bước tiếp theo: làm mô hình hố ga tỉ lệ 1:5 và đo thật', { x: 9.05, y: 5.55, w: 3.4, h: 1.0, fontSize: 14, bold: true, color: HEX.accent5 });
  s.addNotes('Giám khảo luôn hỏi: có làm được thật không. Trả lời bằng bảng rủi ro: mỗi rủi ro đều đã có cách xử lý cụ thể trong thiết kế.');

  // ===== 21. Da Nang =====
  s = pres.addSlide({ masterName: 'CONTENT', sectionTitle: 'Sáng tạo – Giá thành – Áp dụng' });
  s.addText('Áp dụng thực tế tại Đà Nẵng', { placeholder: 'title' });
  const dn = [['FaSatelliteDish', HEX.accent1, 'Trạm quan trắc', 'Kênh, âu thuyền và cửa xả hay bị phản ánh ô nhiễm, ví dụ kênh Phú Lộc, âu thuyền Thọ Quang, các cửa xả ven biển'],
    ['FaFilter', HEX.accent4, 'Hố ga thụ động', 'Lắp dần vào hố ga hàm ếch có sẵn trên các tuyến hay ngập và các tuyến đổ ra cửa xả biển'],
    ['FaBell', HEX.accent3, 'Hộp cứu hộ', 'Trụ điện ở hẻm trũng, gần chợ, trường học, hầm chui và các điểm ngập người dân đã phản ánh qua app']];
  for (let i = 0; i < 3; i++) { const x = 0.6 + i * 4.1; card(s, x, 1.4, 3.8, 3.0);
    await iconCircle(s, dn[i][0], x + 0.3, 1.65, 0.8, dn[i][1], 'FFFFFF');
    T(s, dn[i][2], { x: x + 1.25, y: 1.7, w: 2.4, h: 0.7, fontSize: 18, bold: true, color: C.text2, valign: 'middle' });
    T(s, dn[i][3], { x: x + 0.3, y: 2.6, w: 3.25, h: 1.75, fontSize: 14 }); }
  T(s, 'Lộ trình đề xuất', { x: 0.6, y: 4.65, w: 6, h: 0.4, fontSize: 18, bold: true, color: C.text2 });
  const road = [['1', 'Thí điểm 1 tuyến', '1 trạm + 5 hố ga + 2 hộp cứu hộ'], ['2', 'Đo 1 mùa mưa', 'Độ đục nước ra, kg rác chặn, phút cảnh báo sớm'], ['3', 'Nhân rộng', 'Ưu tiên điểm ngập và cửa xả theo dữ liệu thu được']];
  for (let i = 0; i < 3; i++) { const x = 0.6 + i * 4.1;
    s.addShape(pres.shapes.OVAL, { x, y: 5.2, w: 0.6, h: 0.6, fill: { color: HEX.accent2 }, line: { color: HEX.accent2 } });
    T(s, road[i][0], { x, y: 5.2, w: 0.6, h: 0.6, fontSize: 18, bold: true, color: C.background1, align: 'center', valign: 'middle' });
    T(s, road[i][1], { x: x + 0.75, y: 5.15, w: 3.1, h: 0.4, fontSize: 16, bold: true, color: C.text2 });
    T(s, road[i][2], { x: x + 0.75, y: 5.55, w: 3.1, h: 0.9, fontSize: 14 }); }
  s.addNotes('Địa điểm là ví dụ gợi ý để thí điểm, cần phối hợp với đơn vị quản lý thoát nước và môi trường của thành phố để chọn điểm cụ thể.');

  // ===== 22. Other provinces =====
  s = pres.addSlide({ masterName: 'CONTENT', sectionTitle: 'Sáng tạo – Giá thành – Áp dụng' });
  s.addText('Nhân rộng ra các tỉnh thành khác', { placeholder: 'title' });
  const pv = [['TP. Hồ Chí Minh', 'Triều cường + mưa lớn cùng lúc', 'Hố ga 2 đường một chiều + ống đo triều báo sớm'],
    ['Cần Thơ, Đồng bằng sông Cửu Long', 'Triều dâng vào cống, kênh rạch ô nhiễm', 'Trạm quan trắc kênh rạch + hố ga chống triều'],
    ['Hà Nội và đô thị phía Bắc', 'Ngập do mưa lớn, sông nội đô ô nhiễm', 'Hố ga giữ nước đợt đầu + hộp cứu hộ ở điểm ngập'],
    ['Huế, Hội An, miền Trung', 'Lũ lên nhanh, hay mất điện khi bão', 'Hộp cứu hộ pin mặt trời + LoRa, nút SOS']];
  for (let i = 0; i < 4; i++) { const x = 0.6 + (i % 2) * 6.15, y = 1.4 + Math.floor(i / 2) * 2.45; card(s, x, y, 5.95, 2.2);
    await iconCircle(s, 'FaMapMarkerAlt', x + 0.3, y + 0.3, 0.7, i % 2 ? HEX.accent4 : HEX.accent1, 'FFFFFF');
    T(s, pv[i][0], { x: x + 1.2, y: y + 0.3, w: 4.5, h: 0.7, fontSize: 18, bold: true, color: C.text2, valign: 'middle' });
    T(s, [{ text: 'Vấn đề: ', options: { bold: true } }, { text: pv[i][1], options: { breakLine: true } }, { text: 'Dùng lớp: ', options: { bold: true, color: HEX.accent1 } }, { text: pv[i][2] }], { x: x + 1.2, y: y + 1.05, w: 4.5, h: 1.05, fontSize: 14 }); }
  T(s, 'Thiết kế dạng module: mỗi địa phương chọn lớp phù hợp, cùng dùng chung máy chủ, App và Web.', { x: 0.6, y: 6.35, w: 12.1, h: 0.45, fontSize: 15, bold: true, color: C.text2 });

  // ===== 23. Conclusion =====
  pres.addSection({ title: 'Kết luận' });
  s = pres.addSlide({ masterName: 'TITLE_DARK', sectionTitle: 'Kết luận' });
  s.addText('Kết luận', { placeholder: 'title' });
  s.addText('DELTA-3 bảo vệ thành phố trước, trong và sau mỗi cơn mưa', { placeholder: 'body' });
  const cc = [['Phát hiện sớm', 'Trạm quan trắc có vũ lượng kế, AI không báo nhầm mùa mưa, giữ bằng chứng xả thải', HEX.accent1],
    ['Chặn tận gốc', 'Hố ga v4.1 qua 5 bước nghiên cứu: chặn rác, giữ nước bẩn đợt đầu, chống triều, không dùng điện', HEX.accent4],
    ['Cảnh báo kịp thời', 'Hộp cứu hộ đèn + còi + SOS, chạy khi mất điện, khoảng 2 triệu đồng/hộp', HEX.accent3]];
  for (let i = 0; i < 3; i++) { const y = 1.0 + i * 1.75; s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x: 8.2, y, w: 4.5, h: 1.5, rectRadius: 0.12, fill: { color: '124C5B' }, line: { color: '124C5B' } });
    T(s, cc[i][0], { x: 8.45, y: y + 0.12, w: 4.1, h: 0.45, fontSize: 18, bold: true, color: cc[i][2] === HEX.accent4 ? '7CC4E4' : cc[i][2] });
    T(s, cc[i][1], { x: 8.45, y: y + 0.57, w: 4.1, h: 0.85, fontSize: 14, color: C.background1 }); }
  T(s, 'Xin cảm ơn Ban giám khảo!', { x: 0.7, y: 5.4, w: 7.2, h: 0.6, fontSize: 24, bold: true, color: HEX.accent2, fontFace: THEME.headFontFace });

  await pres.writeFile({ fileName: OUT });
  await applyTheme(OUT, THEME);
  console.log('done');
})().catch(e => { console.error(e); process.exit(1); });
