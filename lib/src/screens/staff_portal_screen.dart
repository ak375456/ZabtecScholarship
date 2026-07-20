import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/common.dart';

class StaffPortalScreen extends StatefulWidget {
  const StaffPortalScreen({
    super.key,
    required this.api,
    required this.session,
    required this.onLogout,
  });

  final ApiClient api;
  final AuthSession session;
  final Future<void> Function() onLogout;

  @override
  State<StaffPortalScreen> createState() => _StaffPortalScreenState();
}

class _StaffPortalScreenState extends State<StaffPortalScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;

  List<(IconData, String)> get _items => widget.session.user.isAdmin
      ? const [
          (Icons.dashboard_outlined, 'Dashboard'),
          (Icons.assignment_outlined, 'Applications'),
          (Icons.school_outlined, 'Students'),
          (Icons.people_outline, 'Users'),
          (Icons.payments_outlined, 'Payments'),
        ]
      : const [
          (Icons.dashboard_outlined, 'Dashboard'),
          (Icons.rate_review_outlined, 'Review Queue'),
          (Icons.analytics_outlined, 'Reports'),
        ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 920;
    final pages = widget.session.user.isAdmin
        ? [
            _AdminDashboard(api: widget.api),
            _ApplicationsPanel(api: widget.api, role: 'admin'),
            _StudentsPanel(api: widget.api),
            _UsersPanel(api: widget.api),
            _PaymentsPanel(api: widget.api),
          ]
        : [
            _HecDashboard(api: widget.api),
            _ApplicationsPanel(api: widget.api, role: 'hec'),
            _ReportsPanel(api: widget.api),
          ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: wide
          ? null
          : Drawer(
              width: MediaQuery.sizeOf(context).width.clamp(280, 330),
              child: SafeArea(
                child: _StaffMenu(
                  account: widget.session.user,
                  items: _items,
                  selectedIndex: _index,
                  onSelected: _selectPage,
                  onLogout: widget.onLogout,
                ),
              ),
            ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 72,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: wide
            ? null
            : IconButton(
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Open menu',
              ),
        title: wide
            ? const BrandMark(compact: true)
            : Text(
                _items[_index].$2,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Chip(
              avatar: const Icon(Icons.verified_user_outlined, size: 18),
              label: Text(widget.session.user.roleLabel),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Row(
        children: [
          if (wide)
            SizedBox(
              width: 250,
              child: _StaffMenu(
                account: widget.session.user,
                items: _items,
                selectedIndex: _index,
                onSelected: _selectPage,
                onLogout: widget.onLogout,
              ),
            ),
          Expanded(
            child: IndexedStack(index: _index, children: pages),
          ),
        ],
      ),
    );
  }

  void _selectPage(int index) {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
    setState(() => _index = index);
  }
}

class _StaffMenu extends StatelessWidget {
  const _StaffMenu({
    required this.account,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.onLogout,
  });

  final Account account;
  final List<(IconData, String)> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
    child: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.deepBlue,
                child: Text(
                  account.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      account.roleLabel,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: items.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: ListTile(
                onTap: () => onSelected(index),
                selected: selectedIndex == index,
                selectedTileColor: const Color(0xFFEAF3FB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                leading: Icon(
                  items[index].$1,
                  color: selectedIndex == index
                      ? AppColors.zaptecBlue
                      : AppColors.muted,
                ),
                title: Text(
                  items[index].$2,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selectedIndex == index
                        ? AppColors.deepBlue
                        : AppColors.muted,
                  ),
                ),
              ),
            ),
          ),
        ),
        const Divider(),
        ListTile(
          onTap: onLogout,
          leading: const Icon(Icons.logout_rounded, color: AppColors.muted),
          title: const Text(
            'Sign out',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _AdminDashboard extends StatefulWidget {
  const _AdminDashboard({required this.api});
  final ApiClient api;

  @override
  State<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<_AdminDashboard> {
  late Future<Map<String, dynamic>> _future = widget.api.adminDashboard();

  @override
  Widget build(BuildContext context) => _FuturePanel(
    title: 'Admin dashboard',
    future: _future,
    onRefresh: () => setState(() => _future = widget.api.adminDashboard()),
    builder: (data) {
      final byStatus = _map(data['byStatus']);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetricGrid(
            cards: [
              _MetricData('Students', data['totalStudents'] ?? 0, Icons.school),
              _MetricData(
                'Applications',
                data['totalApplications'] ?? 0,
                Icons.assignment,
              ),
              _MetricData('Approved', byStatus['approved'] ?? 0, Icons.check),
              _MetricData('Rejected', byStatus['rejected'] ?? 0, Icons.close),
            ],
          ),
          const SizedBox(height: 18),
          _MapList(
            title: 'Recent applications',
            items: _list(data['recentApplications']),
          ),
        ],
      );
    },
  );
}

class _HecDashboard extends StatefulWidget {
  const _HecDashboard({required this.api});
  final ApiClient api;

  @override
  State<_HecDashboard> createState() => _HecDashboardState();
}

class _HecDashboardState extends State<_HecDashboard> {
  late Future<Map<String, dynamic>> _future = widget.api.hecDashboard();

  @override
  Widget build(BuildContext context) => _FuturePanel(
    title: 'HEC dashboard',
    future: _future,
    onRefresh: () => setState(() => _future = widget.api.hecDashboard()),
    builder: (data) {
      final queue = _map(data['queue']);
      final outcomes = _map(data['outcomes']);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetricGrid(
            cards: [
              _MetricData(
                'Pending',
                queue['pending'] ?? 0,
                Icons.pending_actions,
              ),
              _MetricData(
                'Under review',
                queue['underReview'] ?? 0,
                Icons.rate_review,
              ),
              _MetricData('Approved', outcomes['approved'] ?? 0, Icons.check),
              _MetricData(
                'Reviewed by me',
                data['reviewedByMe'] ?? 0,
                Icons.person_search,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _MapList(
            title: 'Recent pending',
            items: _list(data['recentPending']),
          ),
        ],
      );
    },
  );
}

class _ApplicationsPanel extends StatefulWidget {
  const _ApplicationsPanel({required this.api, required this.role});
  final ApiClient api;
  final String role;

  @override
  State<_ApplicationsPanel> createState() => _ApplicationsPanelState();
}

class _ApplicationsPanelState extends State<_ApplicationsPanel> {
  final _search = TextEditingController();
  String? _status;
  late Future<Map<String, dynamic>> _future = _load();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _FuturePanel(
    title: widget.role == 'admin' ? 'Applications' : 'Review queue',
    future: _future,
    onRefresh: () => setState(() => _future = _load()),
    header: FormCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 680;
          final controls = [
            SizedBox(
              width: compact ? double.infinity : 320,
              child: TextField(
                controller: _search,
                decoration: const InputDecoration(
                  labelText: 'Search',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onSubmitted: (_) => setState(() => _future = _load()),
              ),
            ),
            SizedBox(
              width: compact ? double.infinity : 220,
              child: DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('All')),
                  ..._statuses.map(
                    (status) =>
                        DropdownMenuItem(value: status, child: Text(status)),
                  ),
                ],
                onChanged: (value) => setState(
                  () => _status = value?.isEmpty == true ? null : value,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => setState(() => _future = _load()),
              icon: const Icon(Icons.search_rounded),
              label: const Text('Apply'),
            ),
          ];
          return Wrap(spacing: 12, runSpacing: 12, children: controls);
        },
      ),
    ),
    builder: (data) {
      final applications = _list(data['applications']);
      if (applications.isEmpty) {
        return const _EmptyState(message: 'No applications found.');
      }
      return Column(
        children: applications
            .map(
              (item) => _ApplicationTile(
                data: _map(item),
                onTap: () => _openApplication(_map(item)),
              ),
            )
            .toList(),
      );
    },
  );

  Future<Map<String, dynamic>> _load() {
    if (widget.role == 'admin') {
      return widget.api.adminApplications(
        status: _status,
        search: _search.text.trim(),
      );
    }
    return widget.api.hecApplications(
      status: _status,
      search: _search.text.trim(),
    );
  }

  Future<void> _openApplication(Map<String, dynamic> row) async {
    final id = row['_id']?.toString() ?? '';
    if (id.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (context) => _ApplicationDialog(
        api: widget.api,
        role: widget.role,
        applicationId: id,
      ),
    );
    if (mounted) setState(() => _future = _load());
  }
}

class _ApplicationTile extends StatelessWidget {
  const _ApplicationTile({required this.data, required this.onTap});

  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final student = _map(data['student']);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(child: Icon(Icons.assignment_outlined)),
        title: Text(data['applicationNumber']?.toString() ?? 'Application'),
        subtitle: Text(
          [
            if (student['fullName'] != null) student['fullName'],
            if (student['cnic'] != null) student['cnic'],
          ].join(' • '),
        ),
        trailing: _StatusChip(status: data['status']?.toString() ?? 'draft'),
      ),
    );
  }
}

class _ApplicationDialog extends StatefulWidget {
  const _ApplicationDialog({
    required this.api,
    required this.role,
    required this.applicationId,
  });

  final ApiClient api;
  final String role;
  final String applicationId;

  @override
  State<_ApplicationDialog> createState() => _ApplicationDialogState();
}

class _ApplicationDialogState extends State<_ApplicationDialog> {
  final _notes = TextEditingController();
  String _status = 'under_review';
  late Future<Map<String, dynamic>> _future = _load();
  bool _saving = false;
  bool _hydrated = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.role == 'admin' ? 'Application' : 'Review application'),
    content: SizedBox(
      width: 760,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Text('Could not load application: ${snapshot.error}');
          }
          final app = snapshot.data ?? {};
          if (!_hydrated) {
            _status = app['status']?.toString() ?? _status;
            _notes.text = app['reviewNotes']?.toString() ?? '';
            _hydrated = true;
          }
          final student = _map(app['student']);
          final documents = _list(app['documents']);
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DetailRows(
                  rows: {
                    'Application': app['applicationNumber'] ?? '-',
                    'Status': app['status'] ?? '-',
                    'Student': student['fullName'] ?? '-',
                    'CNIC': student['cnic'] ?? '-',
                    'Email': student['email'] ?? '-',
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'New status'),
                  items: (widget.role == 'hec' ? _hecStatuses : _statuses)
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notes,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Review notes'),
                ),
                if (documents.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    'Documents',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...documents.map(
                    (doc) => _DocumentReviewTile(
                      api: widget.api,
                      doc: _map(doc),
                      enabled: widget.role == 'hec',
                      onChanged: () => setState(() => _future = _load()),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Close'),
      ),
      ElevatedButton.icon(
        onPressed: _saving ? null : _save,
        icon: _saving
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_rounded),
        label: Text(_saving ? 'Saving...' : 'Save status'),
      ),
    ],
  );

  Future<Map<String, dynamic>> _load() => widget.role == 'admin'
      ? widget.api.adminApplication(widget.applicationId)
      : widget.api.hecApplication(widget.applicationId);

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      if (widget.role == 'admin') {
        await widget.api.adminUpdateStatus(
          widget.applicationId,
          status: _status,
          reviewNotes: _notes.text.trim(),
        );
      } else {
        await widget.api.hecReviewApplication(
          widget.applicationId,
          status: _status,
          reviewNotes: _notes.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _DocumentReviewTile extends StatelessWidget {
  const _DocumentReviewTile({
    required this.api,
    required this.doc,
    required this.enabled,
    required this.onChanged,
  });

  final ApiClient api;
  final Map<String, dynamic> doc;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(
        doc['isVerified'] == true
            ? Icons.verified_rounded
            : Icons.description_outlined,
        color: doc['isVerified'] == true ? AppColors.leafGreen : null,
      ),
      title: Text(doc['documentType']?.toString() ?? 'Document'),
      subtitle: Text(doc['originalName']?.toString() ?? ''),
      trailing: enabled
          ? Wrap(
              spacing: 8,
              children: [
                IconButton(
                  onPressed: () => _verify(context, true),
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: 'Verify',
                ),
                IconButton(
                  onPressed: () => _verify(context, false),
                  icon: const Icon(Icons.cancel_outlined),
                  tooltip: 'Reject',
                ),
              ],
            )
          : null,
    ),
  );

  Future<void> _verify(BuildContext context, bool verified) async {
    final reason = verified
        ? null
        : await showDialog<String>(
            context: context,
            builder: (context) {
              final controller = TextEditingController();
              return AlertDialog(
                title: const Text('Rejection reason'),
                content: TextField(
                  controller: controller,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Reason'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, controller.text),
                    child: const Text('Reject'),
                  ),
                ],
              );
            },
          );
    if (!verified && (reason == null || reason.trim().isEmpty)) return;
    await api.hecVerifyDocument(
      doc['_id'].toString(),
      verified: verified,
      rejectionReason: reason,
    );
    onChanged();
  }
}

class _StudentsPanel extends StatefulWidget {
  const _StudentsPanel({required this.api});
  final ApiClient api;

  @override
  State<_StudentsPanel> createState() => _StudentsPanelState();
}

class _StudentsPanelState extends State<_StudentsPanel> {
  final _search = TextEditingController();
  late Future<Map<String, dynamic>> _future = _load();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _FuturePanel(
    title: 'Students',
    future: _future,
    onRefresh: () => setState(() => _future = _load()),
    header: FormCard(
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(labelText: 'Search students'),
              onSubmitted: (_) => setState(() => _future = _load()),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => setState(() => _future = _load()),
            icon: const Icon(Icons.search_rounded),
            label: const Text('Search'),
          ),
        ],
      ),
    ),
    builder: (data) =>
        _MapList(title: 'Student accounts', items: _list(data['students'])),
  );

  Future<Map<String, dynamic>> _load() =>
      widget.api.adminStudents(search: _search.text.trim());
}

class _UsersPanel extends StatefulWidget {
  const _UsersPanel({required this.api});
  final ApiClient api;

  @override
  State<_UsersPanel> createState() => _UsersPanelState();
}

class _UsersPanelState extends State<_UsersPanel> {
  late Future<Map<String, dynamic>> _future = widget.api.adminUsers();

  @override
  Widget build(BuildContext context) => _FuturePanel(
    title: 'Users',
    future: _future,
    onRefresh: () => setState(() => _future = widget.api.adminUsers()),
    header: Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: _createStaff,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Create staff user'),
      ),
    ),
    builder: (data) {
      final users = _list(data['users']);
      return Column(
        children: users.map((item) {
          final user = _map(item);
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(user['fullName']?.toString() ?? 'User'),
              subtitle: Text('${user['email'] ?? ''} • ${user['role'] ?? ''}'),
              trailing: Switch(
                value: user['isActive'] != false,
                onChanged: user['role'] == 'admin'
                    ? null
                    : (_) async {
                        await widget.api.adminToggleUserStatus(
                          user['_id'].toString(),
                        );
                        if (mounted) {
                          setState(() => _future = widget.api.adminUsers());
                        }
                      },
              ),
            ),
          );
        }).toList(),
      );
    },
  );

  Future<void> _createStaff() async {
    await showDialog<void>(
      context: context,
      builder: (context) => _CreateStaffDialog(api: widget.api),
    );
    if (mounted) setState(() => _future = widget.api.adminUsers());
  }
}

class _CreateStaffDialog extends StatefulWidget {
  const _CreateStaffDialog({required this.api});
  final ApiClient api;

  @override
  State<_CreateStaffDialog> createState() => _CreateStaffDialogState();
}

class _CreateStaffDialogState extends State<_CreateStaffDialog> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _cnic = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  String _role = 'hec';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _cnic.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Create staff user'),
    content: SizedBox(
      width: 560,
      child: Form(
        key: _key,
        child: SingleChildScrollView(
          child: FormGrid(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (value) => requiredText(value, 'Full name'),
              ),
              TextFormField(
                controller: _cnic,
                decoration: const InputDecoration(labelText: 'CNIC'),
                validator: validateCnic,
              ),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: validateEmail,
              ),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (value) => requiredText(value, 'Phone'),
              ),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: validatePassword,
              ),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'hec', child: Text('HEC')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) => setState(() => _role = value ?? 'hec'),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Creating...' : 'Create'),
      ),
    ],
  );

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.api.adminCreateStaff({
        'fullName': _name.text.trim(),
        'cnic': _cnic.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'password': _password.text,
        'role': _role,
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _PaymentsPanel extends StatefulWidget {
  const _PaymentsPanel({required this.api});
  final ApiClient api;

  @override
  State<_PaymentsPanel> createState() => _PaymentsPanelState();
}

class _PaymentsPanelState extends State<_PaymentsPanel> {
  late Future<Map<String, dynamic>> _future = widget.api.adminPaymentStats();

  @override
  Widget build(BuildContext context) => _FuturePanel(
    title: 'Payment stats',
    future: _future,
    onRefresh: () => setState(() => _future = widget.api.adminPaymentStats()),
    builder: (data) => _MetricGrid(
      cards: [
        _MetricData(
          'Revenue PKR',
          data['totalRevenuePKR'] ?? 0,
          Icons.payments,
        ),
        _MetricData(
          'Completed',
          data['completedPayments'] ?? 0,
          Icons.check_circle,
        ),
        _MetricData('Pending', data['pendingPayments'] ?? 0, Icons.pending),
      ],
    ),
  );
}

class _ReportsPanel extends StatefulWidget {
  const _ReportsPanel({required this.api});
  final ApiClient api;

  @override
  State<_ReportsPanel> createState() => _ReportsPanelState();
}

class _ReportsPanelState extends State<_ReportsPanel> {
  late Future<Map<String, dynamic>> _future = widget.api.hecReports();

  @override
  Widget build(BuildContext context) => _FuturePanel(
    title: 'Reports',
    future: _future,
    onRefresh: () => setState(() => _future = widget.api.hecReports()),
    builder: (data) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MapList(title: 'By status', items: _list(data['byStatus'])),
        const SizedBox(height: 18),
        _MapList(title: 'By month', items: _list(data['byMonth'])),
        const SizedBox(height: 18),
        _MapList(
          title: 'Province distribution',
          items: _list(data['provinceDistribution']),
        ),
      ],
    ),
  );
}

class _FuturePanel extends StatelessWidget {
  const _FuturePanel({
    required this.title,
    required this.future,
    required this.builder,
    required this.onRefresh,
    this.header,
  });

  final String title;
  final Future<Map<String, dynamic>> future;
  final Widget Function(Map<String, dynamic> data) builder;
  final VoidCallback onRefresh;
  final Widget? header;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () async => onRefresh(),
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 520 ? 18 : 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.sync_rounded),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (header != null) ...[header!, const SizedBox(height: 18)],
              FutureBuilder<Map<String, dynamic>>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SizedBox(
                      height: 260,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return _EmptyState(
                      message: 'Could not load data: ${snapshot.error}',
                    );
                  }
                  return builder(snapshot.data ?? {});
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.cards});
  final List<_MetricData> cards;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 900
          ? 4
          : constraints.maxWidth >= 620
          ? 2
          : 1;
      const gap = 14.0;
      final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: cards
            .map(
              (card) => SizedBox(
                width: width,
                child: _MetricCard(data: card),
              ),
            )
            .toList(),
      );
    },
  );
}

class _MetricData {
  const _MetricData(this.label, this.value, this.icon);
  final String label;
  final Object value;
  final IconData icon;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});
  final _MetricData data;

  @override
  Widget build(BuildContext context) => FormCard(
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFFEAF3FB),
          child: Icon(data.icon, color: AppColors.zaptecBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.label, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 4),
              Text(
                data.value.toString(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MapList extends StatelessWidget {
  const _MapList({required this.title, required this.items});

  final String title;
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) => FormCard(
    title: title,
    icon: Icons.list_alt_outlined,
    child: items.isEmpty
        ? const Text('No records.', style: TextStyle(color: AppColors.muted))
        : Column(
            children: items.map((item) {
              final map = _map(item);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  _summarize(map),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
          ),
  );
}

class _DetailRows extends StatelessWidget {
  const _DetailRows({required this.rows});
  final Map<String, Object?> rows;

  @override
  Widget build(BuildContext context) => Column(
    children: rows.entries
        .map(
          (entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value?.toString() ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(status.replaceAll('_', ' ')),
    visualDensity: VisualDensity.compact,
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => FormCard(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
      ),
    ),
  );
}

const _statuses = [
  'draft',
  'submitted',
  'under_review',
  'approved',
  'rejected',
  'waitlisted',
];

const _hecStatuses = ['approved', 'rejected', 'waitlisted', 'under_review'];

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

List<dynamic> _list(Object? value) => value is List ? value : const [];

String _summarize(Map<String, dynamic> map) {
  final student = _map(map['student']);
  final parts = [
    map['applicationNumber'],
    student['fullName'],
    map['fullName'],
    map['email'],
    map['cnic'],
    map['status'],
    if (map['_id'] != null && map.length <= 3) '${map['_id']}: ${map['count']}',
  ].where((value) => value != null && value.toString().isNotEmpty).toList();
  if (parts.isNotEmpty) return parts.join(' • ');
  return map.entries.map((entry) => '${entry.key}: ${entry.value}').join(' • ');
}
