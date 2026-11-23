"""AI 1 — phân biệt "nước mưa chảy tràn" và "nghi xả thải lén" (chạy trên server FastAPI).
Bản luật đơn giản để demo; khi có đủ dữ liệu gắn nhãn thì thay bằng cây quyết định (sklearn).
"""


def classify(tds, turbidity, depth_rise_cm_per_h, rain_mm_h, hour, tds_base, turb_base):
    tds_jump = tds / max(tds_base, 1)
    turb_jump = turbidity / max(turb_base, 1)
    raining = rain_mm_h >= 2
    night = hour >= 22 or hour < 5

    if raining and depth_rise_cm_per_h > 5 and turb_jump > 1.5 and tds_jump < 1.5:
        return "runoff"            # mưa cuốn đất cát: đục tăng nhưng TDS loãng ra
    if not raining and (tds_jump > 2 or turb_jump > 3):
        return "suspect_discharge" if night or tds_jump > 3 else "watch"
    if raining and tds_jump > 2.5:
        return "suspect_discharge"  # lợi dụng mưa để xả: TDS vẫn tăng dù bị pha loãng
    return "normal"


def flood_risk(rain_next_3h_mm, tide_cm, depth_cm, rise_cm_per_h, trap_full_pct):
    """AI 2 — điểm nguy cơ ngập 0..2 (luật khởi đầu, sau này học trọng số từ dữ liệu)."""
    score = rain_next_3h_mm / 30 + max(tide_cm - 150, 0) / 50 + depth_cm / 20 + rise_cm_per_h / 10 + trap_full_pct / 100
    return 2 if score >= 3 else 1 if score >= 1.5 else 0


if __name__ == "__main__":
    assert classify(300, 90, 8, 15, 14, 280, 30) == "runoff"
    assert classify(1200, 60, 0, 0, 2, 280, 30) == "suspect_discharge"
    assert classify(290, 32, 0, 0, 10, 280, 30) == "normal"
    assert flood_risk(60, 180, 15, 12, 80) == 2
    assert flood_risk(0, 100, 0, 0, 10) == 0
    print("ok")
