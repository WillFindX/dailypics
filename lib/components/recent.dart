import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:daily_pics/main.dart';
import 'package:daily_pics/misc/bean.dart';
import 'package:daily_pics/misc/utils.dart';
import 'package:daily_pics/pages/details.dart';
import 'package:daily_pics/pages/search.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_ionicons/flutter_ionicons.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RecentComponent extends StatefulWidget {
  @override
  _RecentComponentState createState() => _RecentComponentState();
}

class _RecentComponentState extends State<RecentComponent>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  ScrollController controller;
  Map<int, List<Picture>> data = {0: [], 1: [], 2: []};
  bool doing = false;
  int index = 0;
  Map<int, int> cur = {0: 1, 1: 1, 2: 1};
  Map<int, int> max = {0: null, 1: null, 2: null};

  @override
  void initState() {
    super.initState();
    controller = ScrollController(
      initialScrollOffset: kSearchBarHeight,
    )..addListener(_onScrollUpdate);
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    double windowHeight = MediaQuery.of(context).size.height;
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        CupertinoScrollbar(
          controller: controller,
          child: NotificationListener<UserScrollNotification>(
            onNotification: (UserScrollNotification notification) {
              if (notification.direction == ScrollDirection.idle) {
                _onScrollEnd();
              }
              return false;
            },
            child: CustomScrollView(
              controller: controller,
              physics: BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: <Widget>[
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverHeaderDelegate(
                    index: index,
                    vsync: this,
                    onValueChanged: (newValue) {
                      if (!doing) {
                        setState(() => index = newValue);
                        if (data[index].length == 0) {
                          _fetchData();
                        }
                      }
                    },
                  ),
                ),
                CupertinoSliverRefreshControl(onRefresh: _fetchData),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: data[index].length == 0 ? windowHeight : 0,
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
                  sliver: SliverStaggeredGrid.countBuilder(
                    crossAxisCount: Device.isIPad(context) ? 3 : 2,
                    itemCount: data[index].length,
                    itemBuilder: (_, i) => _Tile(data[index][i], i),
                    staggeredTileBuilder: (_) => StaggeredTile.fit(1),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        data[index].length == 0 ? CupertinoActivityIndicator() : Container(),
      ],
    );
  }

  Future<void> _fetchData() async {
    doing = true;
    List<String> types = [C.type_photo, C.type_illus, C.type_deskt];
    String uri =
        'https://v2.api.dailypics.cn/list?page=${cur[index]}&size=20&op=desc&sor'
        't=${types[index]}';
    dynamic json = jsonDecode((await http.get(uri)).body);
    Response res = Response.fromJson({'data': json['result']});
    data[index].addAll(await _parseMark(res.data));
    max[index] = json['maxpage'];
    doing = false;
    setState(() {});
  }

  Future<List<Picture>> _parseMark(List<Picture> pics) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList('marked') ?? [];
    for (int i = 0; i < pics.length; i++) {
      pics[i].marked = list.contains(pics[i].id);
    }
    return pics;
  }

  void _onScrollUpdate() {
    ScrollPosition pos = controller.position;

    bool shouldFetch = pos.maxScrollExtent - pos.pixels < 256 && !doing;
    if (shouldFetch && max[index] - cur[index] > 0) {
      cur[index] += 1;
      _fetchData();
    }
  }

  void _onScrollEnd() {
    ScrollPosition pos = controller.position;

    Duration duration = Duration(milliseconds: 300);
    double half = kSearchBarHeight / 2;
    bool shouldExpand = pos.pixels != 0 && pos.pixels <= half;
    if (shouldExpand) {
      controller.animateTo(0, duration: duration, curve: Curves.ease);
    }

    bool shouldFold = pos.pixels > half && pos.pixels < kSearchBarHeight;
    if (shouldFold) {
      controller.animateTo(
        kSearchBarHeight,
        duration: duration,
        curve: Curves.ease,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    controller.removeListener(_onScrollUpdate);
    controller.dispose();
  }

  @override
  bool get wantKeepAlive => data != null;
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final ValueChanged<int> onValueChanged;

  final TickerProvider vsync;

  final int index;

  _SliverHeaderDelegate({
    @required this.onValueChanged,
    @required this.vsync,
    @required this.index,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, _) {
    double extent = math.min<double>(shrinkOffset, kSearchBarHeight);
    double barHeight = kSearchBarHeight - extent;
    EdgeInsets padding = MediaQuery.of(context).padding;
    CupertinoThemeData theme = CupertinoTheme.of(context);
    TextStyle navTitleTextStyle = theme.textTheme.navTitleTextStyle;
    return OverflowBox(
      minHeight: 0,
      maxHeight: double.infinity,
      alignment: Alignment.topCenter,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.only(top: padding.top, bottom: 8),
            decoration: BoxDecoration(
              color: CupertinoTheme.of(context).barBackgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: Color(0x4c000000),
                  width: 0,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  height: 44,
                  alignment: Alignment.center,
                  child: Text(
                    '以往',
                    style: navTitleTextStyle,
                  ),
                ),
                SizedBox(
                  height: barHeight,
                  child: SearchBar(
                    shrinkOffset: barHeight / kSearchBarHeight,
                    onTap: () => SearchPage.push(context),
                  ),
                ),
                SizedBox(
                  width: 500,
                  child: DefaultTextStyle(
                    style: TextStyle(fontWeight: FontWeight.w500),
                    child: CupertinoSegmentedControl<int>(
                      onValueChanged: onValueChanged,
                      groupValue: index,
                      children: {
                        0: Text('杂烩'),
                        1: Text('插画'),
                        2: Text('桌面'),
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 154;

  @override
  double get minExtent => 105;

  @override
  bool shouldRebuild(_) => true;
}

class _Tile extends StatefulWidget {
  final Picture data;

  final int index;

  _Tile(this.data, this.index);

  @override
  State<StatefulWidget> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  @override
  Widget build(BuildContext context) {
    double aspectRatio = widget.data.width / widget.data.height;
    if (aspectRatio > 4 / 5 && !Device.isIPad(context)) {
      aspectRatio = 4 / 5;
    }
    return GestureDetector(
      onTap: () async {
        await DetailsPage.push(
          context,
          data: widget.data,
          heroTag: '${widget.index}-${widget.data.id}',
        );
        setState(() {});
      },
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xffffffff),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Color(0xffd9d9d9),
              offset: Offset(0, 12),
              blurRadius: 24,
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AspectRatio(
                aspectRatio: aspectRatio,
                child: Hero(
                  tag: '${widget.index}-${widget.data.id}',
                  child: CachedNetworkImage(
                    imageUrl: Utils.getCompressed(widget.data),
                    fit: BoxFit.cover,
                    placeholder: (_, __) {
                      return Container(
                        color: Color(0xffe0e0e0),
                        child: Image.asset('res/placeholder.jpg'),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        widget.data.title,
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                    Offstage(
                      offstage: !widget.data.marked,
                      child: Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Ionicons.ios_star, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 8, bottom: 8),
                child: Text(widget.data.date, style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}