import sys
import shutil
from .text_wrap import TextWrap


class Table:
    def __init__(self, terminal_width = None):
        self.padding_size = 1
        self.border_horizontal = "-"
        self.border_vertical = "|"
        self.border_corner = "+"
        self.table_data = []
        self.row_count = 0
        self.column_widths = []
        self.terminal_width = terminal_width if terminal_width is not None else self.get_terminal_width()

    def get_terminal_width(self):
        try:
            return shutil.get_terminal_size().columns
        except:
            return 100

    def display(self, table_data):
        if not table_data:
            return

        self.table_data = table_data
        self.row_count = len(self.table_data)
        self.column_widths = [0] * len(self.table_data[0])

        self.calculate_width_of_all_columns()
        self.adjust_column_widths_for_terminal()
        self.create_text_wrap_object()
        self.render()

    def calculate_width_of_all_columns(self):
        for row in self.table_data:
            self.process_single_row_to_calculate_column_widths(row)

    def process_single_row_to_calculate_column_widths(self, row):
        for i, cell in enumerate(row):
            if i < len(self.column_widths):
                self.column_widths[i] = max(self.column_widths[i], len(str(cell)))
            else:
                print(f"Error: Mismatched number of columns at row: {row}")
                sys.exit(1)

    def adjust_column_widths_for_terminal(self):
        other_columns_width = sum(self.column_widths[1:])  # Sum of all other columns width of content only
        other_columns_width += (len(self.column_widths) - 1) * (self.padding_size * 2)  # Padding of other columns (2 sides)
        other_columns_width += len(self.column_widths) - 1  # Right border of other columns
        other_columns_width += 4  # Border and padding of first column (2 sides)

        self.column_widths[0] = min(self.column_widths[0], self.terminal_width - other_columns_width)

    def create_text_wrap_object(self):
        self.text_wrap = TextWrap(separators=['/', '-', '_'], width=self.column_widths[0])

    def render(self):
        for i, row in enumerate(self.table_data):
            is_header = (i == 0)
            is_last = (i == self.row_count - 1)

            if is_header:
                self.draw_border()

            if len(row[0]) <= self.column_widths[0]:
                self.draw_row(row)
            else:
                self.draw_row_with_wrapping(row)

            if is_header or is_last:
                self.draw_border()

    def draw_border(self):
        print(self.border_corner, end="")
        for width in self.column_widths:
            border_length = width + (self.padding_size * 2)
            print(self.border_horizontal * border_length, end=self.border_corner)
        print()

    def draw_row(self, row_data):
        print(self.border_vertical, end="")
        for i, cell in enumerate(row_data):
            self.draw_cell(cell, self.column_widths[i])
        print()

    def draw_cell(self, cell_content, column_width):
        cell_text = str(cell_content)
        padding = " " * self.padding_size
        spaces = " " * (column_width - len(cell_text))
        print(padding + cell_text + spaces + padding, end=self.border_vertical)

    def draw_row_with_wrapping(self, row_data):
        wrapped_lines = self.text_wrap.wrap(row_data[0])

        for i, line in enumerate(wrapped_lines):
            modified_row = [line] + row_data[1:] if i == 0 else [line] + [""] * (len(row_data) - 1)
            self.draw_row(modified_row)
