import sys
from libs.table import Table


class CheckReport:
    def __init__(self, sync_direction, report_file, terminal_width = None):
        self.sync_direction = sync_direction
        self.report_file = report_file
        self.terminal_width = int(terminal_width) if terminal_width is not None else None
        self.raw_report_data = []
        self.parsed_report_data = []

    def run(self):
        self.get_raw_report_data()
        self.parse_report_data()
        self.display_report()

    def get_raw_report_data(self):
        with open(self.report_file, "r", encoding="utf-8") as file:
            for line in file:
                self.raw_report_data.append(line)

    def parse_report_data(self):
        for line in self.raw_report_data:
            self.parse_single_line_of_raw_report_data(line)

    def parse_single_line_of_raw_report_data(self, line):
        symbol, path = line.strip().split(" ", 1)

        if symbol == "=":
            self.parse_single_line_when_present_in_both_and_identical(path)
        elif symbol == "-":
            self.parse_single_line_when_missing_on_source(path)
        elif symbol == "+":
            self.parse_single_line_when_missing_on_destination(path)
        elif symbol == "*":
            self.parse_single_line_when_present_in_both_but_different(path)
        elif symbol == "!":
            self.parse_single_line_when_error(path)
        else:
            print(f"Unknown symbol: {symbol} in line: {line}")
            sys.exit(1)

    def parse_single_line_when_present_in_both_and_identical(self, path):
        self.parsed_report_data.append([path, "x", "x", "Do nothing"])

    def parse_single_line_when_missing_on_source(self, path):
        if self.sync_direction == "up":
            self.parsed_report_data.append([path, "", "x", "Delete on remote"])
        elif self.sync_direction == "down":
            self.parsed_report_data.append([path, "x", "", "Delete on local"])

    def parse_single_line_when_missing_on_destination(self, path):
        if self.sync_direction == "up":
            self.parsed_report_data.append([path, "x", "", "Upload to remote"])
        elif self.sync_direction == "down":
            self.parsed_report_data.append([path, "", "x", "Download to local"])

    def parse_single_line_when_present_in_both_but_different(self, path):
        if self.sync_direction == "up":
            self.parsed_report_data.append([path, "x", "x", "Overwrite on remote"])
        elif self.sync_direction == "down":
            self.parsed_report_data.append([path, "x", "x", "Overwrite on local"])

    def parse_single_line_when_error(self, path):
        self.parsed_report_data.append([path, "", "", "Error"])

    def display_report(self):
        table_data = self.parsed_report_data
        table_data.insert(0, ["Path", "Local", "Remote", "Action"])
        if self.terminal_width is not None:
            Table(self.terminal_width).display(table_data)
        else:
            Table().display(table_data)


if __name__ == "__main__":
    if len(sys.argv) == 3:
        cr = CheckReport(sys.argv[1], sys.argv[2])
    elif len(sys.argv) == 4:
        cr = CheckReport(sys.argv[1], sys.argv[2], sys.argv[3])
    else:
        print("Usage: python check-report.py <sync-direction> <report-file> [terminal-width]")
        sys.exit(1)

    cr.run()
