import math
import numpy as np
import matplotlib.pyplot as plt


# -------------------------------
# ПАРАМЕТРЫ СИСТЕМЫ
# -------------------------------

# Разомкнутая передаточная функция (из твоего скрина):
# W_раз(s) = 1 / (0.000002 s^3 + 0.0001 s^2 - 0.02 s + 1)
NUM_OPEN = np.array([1.0], dtype=float)
DEN_CLOSED_TARGET = np.array([2e-6, 1e-4, -0.02, 2.0], dtype=float)
pad = len(DEN_CLOSED_TARGET) - len(NUM_OPEN)
NUM_PADDED = np.pad(NUM_OPEN, (pad, 0), mode="constant")
DEN_OPEN = DEN_CLOSED_TARGET - NUM_PADDED
DEN_CLOSED = DEN_CLOSED_TARGET.copy()

CHAR_POLY = (DEN_CLOSED / DEN_CLOSED[0]).tolist()


def get_closed_loop_coeffs():
    """[a0, a1, ...] при D(s) = a0*s^n + ... + an."""
    return CHAR_POLY


def W_open(omega: float) -> complex:
    """Разомкнутая передаточная функция на jω."""
    s = 1j * omega
    num = np.polyval(NUM_OPEN, s)
    den = np.polyval(DEN_OPEN, s)
    return num / den


def D_closed(omega: float) -> complex:
    """Характеристический полином замкнутой системы на jω."""
    s = 1j * omega
    return np.polyval(DEN_CLOSED, s)


# -------------------------------
# РАУС / ГУРВИЦ / КОРНИ
# -------------------------------

def routh_table(coeffs):
    """Строит таблицу Рауса для произвольного полинома."""
    coeffs = np.array(coeffs, dtype=float)
    n = len(coeffs) - 1
    m = (len(coeffs) + 1) // 2
    table = np.zeros((n + 1, m))
    table[0, : len(coeffs[0::2])] = coeffs[0::2]
    table[1, : len(coeffs[1::2])] = coeffs[1::2]

    for i in range(2, n + 1):
        for j in range(m - 1):
            a = table[i - 1, 0]
            if abs(a) < 1e-12:
                a = 1e-12
            table[i, j] = (
                table[i - 1, 0] * table[i - 2, j + 1]
                - table[i - 2, 0] * table[i - 1, j + 1]
            ) / a
        if np.allclose(table[i], 0.0):
            order = n - i
            for k in range(m):
                table[i, k] = table[i - 1, k] * (order - 2 * k)
    return table


def routh_analysis():
    print("=== РАУС ===")
    coeffs = get_closed_loop_coeffs()
    deg = len(coeffs) - 1
    poly_repr = " + ".join(
        f"{c:.4g} s^{deg - idx}" if deg - idx > 1
        else (f"{c:.4g} s" if deg - idx == 1 else f"{c:.4g}")
        for idx, c in enumerate(coeffs)
    )
    print(f"D(s) = {poly_repr}")

    table = routh_table(coeffs)
    print("\nТаблица Рауса:")
    for i, row in enumerate(table):
        power = len(coeffs) - 1 - i
        filtered = [x for x in row if not math.isnan(x)]
        formatted = "\t".join(f"{x:.4g}" for x in filtered)
        print(f"s^{power}: {formatted}")

    first_col = table[:, 0]
    sign_changes = np.sum(first_col[:-1] * first_col[1:] < 0)
    stable = sign_changes == 0 and np.all(first_col > 0)

    print("Первый столбец:", ", ".join(f"{x:.4g}" for x in first_col))
    print("Изменений знака:", int(sign_changes))
    print("Вывод:", "устойчива" if stable else "НЕустойчива")


def hurwitz_matrix(coeffs):
    """Формирует матрицу Гурвица для полинома."""
    coeffs = np.array(coeffs, dtype=float)
    n = len(coeffs) - 1
    size = n
    mat = np.zeros((size, size))
    for i in range(size):
        for j in range(size):
            idx = 2 * i - j + 1
            mat[i, j] = coeffs[idx] if 0 <= idx < len(coeffs) else 0.0
    return mat


def hurwitz_analysis():
    print("\n=== ГУРВИЦ ===")
    coeffs = get_closed_loop_coeffs()
    mat = hurwitz_matrix(coeffs)
    minors = []
    ok = True
    for k in range(1, mat.shape[0] + 1):
        minor = np.linalg.det(mat[:k, :k])
        minors.append(minor)
        if minor <= 0:
            ok = False
    for i, delta in enumerate(minors, start=1):
        print(f"Δ{i} = {delta:.4g}")
    print("Вывод:", "устойчива" if ok else "НЕустойчива")


def root_analysis():
    print("\n=== КОРНИ ХАРАКТЕРИСТИЧЕСКОГО УРАВНЕНИЯ ===")
    coeffs = get_closed_loop_coeffs()
    roots = np.roots(coeffs)
    for i, r in enumerate(roots, start=1):
        sign = "+" if r.imag >= 0 else "-"
        print(f"s{i} = {r.real:.6g}  {sign}  {abs(r.imag):.6g} j")
    unstable = [r for r in roots if r.real > 1e-9]
    print("Вывод:", "устойчива" if not unstable else "НЕустойчива")


# -------------------------------
# КРИВАЯ МИХАЙЛОВА
# -------------------------------

def plot_mikhailov(show=True, save_path=None):
    print("\n=== ПОСТРОЕНИЕ КРИВОЙ МИХАЙЛОВА ===")

    # частоты (можно подстроить диапазон)
    omega_max = 500.0
    n_points = 2000
    omegas = np.linspace(0, omega_max, n_points)

    D_vals = np.array([D_closed(w) for w in omegas])
    Re = D_vals.real
    Im = D_vals.imag

    plt.figure(figsize=(7, 7))
    # фиолетовая кривая, как на скрине
    plt.plot(Re, Im, color="purple", linewidth=2, label="Кривая Михайлова")

    # оси Re=0, Im=0 (чёрные линии)
    plt.axhline(0, color="black", linewidth=1, label="Im=0")
    plt.axvline(0, color="black", linewidth=1, label="Re=0")

    plt.title("Кривая Михайлова D(jω) для замкнутой системы")
    plt.xlabel("Re(D(jω))")
    plt.ylabel("Im(D(jω))")

    # сетка как на рисунке
    plt.grid(True, linestyle="--", linewidth=0.5)
    plt.legend(loc="upper right")

    if save_path is not None:
        plt.savefig(save_path, dpi=300, bbox_inches="tight")
    if show:
        plt.show()
    plt.close()


# -------------------------------
# ГОДОГРАФ НАЙКВИСТА
# -------------------------------

# -------------------------------
# ГОДОГРАФ НАЙКВИСТА (ИСПРАВЛЕННЫЙ)
# -------------------------------

def plot_nyquist(show=True, save_path=None):
    """
    Построение годографа Найквиста для
    W_раз(s) = 1 / (0.000002 s^3 + 0.0001 s^2 - 0.02 s + 1)
    """
    print("\n=== ПОСТРОЕНИЕ ГОДОГРАФА НАЙКВИСТА ===")

    # логарифмическая сетка частот ω
    # (без math.log10 — только numpy)
    omega_min = 1e-2
    omega_max = 1e3
    n_points = 1500

    omegas = np.logspace(
        np.log10(omega_min),
        np.log10(omega_max),
        n_points
    )

    # значения разомкнутой ПФ на jω
    W_vals = np.array([W_open(w) for w in omegas])
    Re = W_vals.real
    Im = W_vals.imag

    # убираем возможные бесконечности/NaN (на всякий случай)
    mask = np.isfinite(Re) & np.isfinite(Im)
    Re = Re[mask]
    Im = Im[mask]

    plt.figure(figsize=(7, 7))
    plt.plot(Re, Im, linewidth=2, color="purple",
             label="Годограф Найквиста")
    plt.scatter([-1], [0], s=60, color="red",
                zorder=5, label="Точка (-1, j0)")
    plt.axhline(0, color="black", linewidth=1)
    plt.axvline(0, color="black", linewidth=1)
    plt.title("Годограф Найквиста W_раз(s) = 1/(2e-6 s^3 + 1e-4 s^2 - 0.02 s + 1)")
    plt.xlabel("Re(W(jω))")
    plt.ylabel("Im(W(jω))")

    plt.grid(True, linestyle="--", linewidth=0.5)
    plt.legend(loc="upper right")

    # при желании можно поджать оси под отчёт
    # plt.xlim(-5, 1)
    # plt.ylim(-3.5, 2.5)

    if save_path is not None:
        plt.savefig(save_path, dpi=300, bbox_inches="tight")
    if show:
        plt.show()
    plt.close()



# -------------------------------
# MAIN
# -------------------------------

def main():
    print("ПОЛНЫЙ АНАЛИЗ СИСТЕМЫ УПРАВЛЕНИЯ")
    print("W_раз(s) = 1 / (0.000002 s^3 + 0.0001 s^2 - 0.02 s + 1)")
    print("W(s) = W_раз(s) / (1 + W_раз(s))")
    print("D(s) = 0.000002 s^3 + 0.0001 s^2 - 0.02 s + 2\n")

    routh_analysis()
    hurwitz_analysis()
    root_analysis()

    # Графики в стиле твоих картинок
    plot_mikhailov(show=True, save_path="mikhailov.png")
    plot_nyquist(show=True, save_path="nyquist.png")
    print("\nГрафики сохранены как 'mikhailov.png' и 'nyquist.png'.")


if __name__ == "__main__":
    main()
