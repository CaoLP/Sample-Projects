import copy, script
from pptx import Presentation
from pptx.util import Pt, Cm
from docx import Document
from docx.shared import Pt as DPt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
RATE = 180/60  # tiếng mỗi giây
t = 0; times = []
for s in script.SEG:
    d = len(s['text'].split())/RATE; times.append((t, t+d)); t += d
fmt = lambda x: f"{int(x//60)}:{int(x%60):02d}"
keep = [s['full'] for s in script.SEG]
# notes into full deck
full = Presentation('DELTA-3_thuyet_trinh.pptx')
for s, (a, b) in zip(script.SEG, times):
    sl = full.slides[s['full']-1]; tf = sl.notes_slide.notes_text_frame
    old = tf.text
    tf.text = f"[{fmt(a)} – {fmt(b)}] {s['text']}" + (f"\n\nGhi chú: {old}" if old else '')
full.save('DELTA-3_thuyet_trinh.pptx')
# short deck: drop slides not in keep
short = Presentation('DELTA-3_thuyet_trinh.pptx')
sldIdLst = short.slides._sldIdLst
for i, sid in reversed(list(enumerate(list(sldIdLst), 1))):
    if i not in keep:
        short.part.drop_rel(sid.rId); sldIdLst.remove(sid)
short.save('DELTA-3_thuyet_trinh_7phut.pptx')
# docx script
doc = Document()
st = doc.styles['Normal']; st.font.name = 'Calibri'; st.font.size = DPt(12)
doc.add_heading('DELTA-3 – Kịch bản thuyết trình (6–7 phút)', 0)
doc.add_paragraph('Phát hiện sớm – Chặn tận gốc – Cảnh báo kịp thời').runs[0].bold = True
doc.add_paragraph(f'Tổng thời lượng ước tính: {fmt(t)} ở tốc độ nói ~180 tiếng/phút. Dùng file DELTA-3_thuyet_trinh_7phut.pptx ({len(keep)} slide); mỗi slide đã có lời thoại trong phần Notes.')
tb = doc.add_table(rows=1, cols=3); tb.style = 'Light Grid Accent 1'
for c, h in zip(tb.rows[0].cells, ['Thời gian', 'Slide', 'Nội dung']): c.text = h
for i, (s, (a, b)) in enumerate(zip(script.SEG, times), 1):
    r = tb.add_row().cells; r[0].text = f'{fmt(a)} – {fmt(b)}'; r[1].text = str(i); r[2].text = s['title']
doc.add_heading('Lời thoại', 1)
for i, (s, (a, b)) in enumerate(zip(script.SEG, times), 1):
    doc.add_heading(f'Slide {i} · {s["title"]}  ({fmt(a)} – {fmt(b)})', 2)
    doc.add_paragraph(s['text'])
doc.add_heading('Câu hỏi Ban giám khảo hay hỏi và gợi ý trả lời', 1)
for q, a in script.QA:
    p = doc.add_paragraph(style='List Number'); p.add_run(q).bold = True
    doc.add_paragraph(a)
doc.add_heading('Mẹo khi trình bày', 1)
for m in ['Chia 2–3 bạn: 1 bạn mở đầu + Lớp 1, 1 bạn Lớp 2 + video, 1 bạn Lớp 3 + sáng tạo, khả thi, kết luận.',
          'Đến slide video: bấm phát rồi nói theo hình, không đọc chữ trên slide.',
          'Mang mô hình thật: trạm quan trắc, hộp cứu hộ bật đèn đổi màu khi đổ nước vào khay.',
          'Nói con số chậm và rõ: 0,85 m³; gấp 10 lần; 100 L/s; khoảng 2 triệu đồng một hộp.',
          'Tập bấm giờ 3 lần; nếu quá 7 phút, rút bớt slide Nhân rộng.']:
    doc.add_paragraph(m, style='List Bullet')
doc.save('DELTA-3_kich_ban_thuyet_trinh.docx')
print(fmt(t), len(keep))
