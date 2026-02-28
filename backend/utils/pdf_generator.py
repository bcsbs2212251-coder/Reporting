from fpdf import FPDF
from datetime import datetime
import io

class DATA_PDF(FPDF):
    def header(self):
        # Logo or Title
        self.set_font('helvetica', 'B', 15)
        self.cell(0, 10, self.report_title, border=False, align='C')
        self.ln(10)
        self.set_font('helvetica', 'I', 10)
        self.cell(0, 10, f'Generated on: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}', border=False, align='R')
        self.ln(15)

    def footer(self):
        self.set_y(-15)
        self.set_font('helvetica', 'I', 8)
        self.cell(0, 10, f'Page {self.page_no()}/{{nb}}', align='C')

def generate_pdf(title, headers, data):
    pdf = DATA_PDF()
    pdf.report_title = title
    pdf.alias_nb_pages()
    pdf.add_page()
    
    # Set background color for header
    pdf.set_fill_color(240, 240, 240)
    pdf.set_font('helvetica', 'B', 10)
    
    # Calculate column widths
    page_width = pdf.w - 2 * pdf.l_margin
    col_width = page_width / len(headers)
    
    # Header
    for header in headers:
        pdf.cell(col_width, 10, str(header), border=1, align='C', fill=True)
    pdf.ln()
    
    # Data
    pdf.set_font('helvetica', '', 9)
    for row in data:
        # Calculate max height needed for this row
        max_line_height = 0
        for item in row:
            # We use multi_cell to handle wrapping, but for a simple table 
            # we'll just truncate or use small cells for now for simplicity
            # in this implementation.
            pass
        
        for item in row:
            # Clean string and truncate if too long
            text = str(item)
            if len(text) > 30: text = text[:27] + "..."
            pdf.cell(col_width, 8, text, border=1, align='L')
        pdf.ln()
        
    # Return as bytes
    return pdf.output()

def generate_reports_pdf(reports):
    headers = ["ID", "User", "Title", "Category", "Priority", "Status"]
    data = []
    for r in reports:
        data.append([
            str(r["_id"])[-6:], # Short ID
            r.get("user_name", "N/A"),
            r.get("title", "N/A"),
            r.get("category", "general"),
            r.get("priority", "medium"),
            r.get("status", "pending")
        ])
    return generate_pdf("Reports Export", headers, data)

def generate_tasks_pdf(tasks):
    headers = ["ID", "Assigned To", "Title", "Priority", "Status", "Due Date"]
    data = []
    for t in tasks:
        due_date = t.get("due_date")
        due_str = due_date.strftime("%Y-%m-%d") if isinstance(due_date, datetime) else str(due_date or "N/A")
        data.append([
            str(t["_id"])[-6:],
            t.get("user_name", t.get("user_id", "N/A")),
            t.get("title", "N/A"),
            t.get("priority", "medium"),
            t.get("status", "pending"),
            due_str
        ])
    return generate_pdf("Tasks Export", headers, data)

def generate_leaves_pdf(leaves):
    headers = ["User", "Type", "Start", "End", "Status"]
    data = []
    for l in leaves:
        data.append([
            l.get("user_name", "N/A"),
            l.get("leave_type", "N/A"),
            str(l.get("start_date", "N/A")),
            str(l.get("end_date", "N/A")),
            l.get("status", "pending")
        ])
    return generate_pdf("Leaves Export", headers, data)

def generate_users_pdf(users):
    headers = ["ID", "Name", "Email", "Role", "Dept", "Location"]
    data = []
    for u in users:
        data.append([
            str(u["_id"])[-6:],
            u.get("full_name", "N/A"),
            u.get("email", "N/A"),
            u.get("role", "employee"),
            u.get("department", "N/A"),
            u.get("location", "N/A")
        ])
    return generate_pdf("Users Export", headers, data)
