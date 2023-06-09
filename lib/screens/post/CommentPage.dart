// ignore_for_file: file_names, non_constant_identifier_names

import 'package:becapy/models/UserClass.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '/helper/GlobalFunctions.dart';
import '/helper/backend/database.dart';
import '/helper/utils/loader.dart';
import '/providers/CurrentPostProvider.dart';
import '/providers/UserProvider.dart';
import '/helper/backend/apis.dart';
import '/models/post.dart';
import '/models/comment.dart';
import '/widgets/upper_widget_bottom_sheet.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentPage extends StatefulWidget {
  final Post post;

  const CommentPage({
    required this.post,
    Key? key,
  }) : super(
          key: key,
        );

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  final TextEditingController _commentController = TextEditingController();

  Future<void> _addComment() async {
    if (_commentController.text.trim().isNotEmpty) {
      UserProvider userProvider =
          Provider.of<UserProvider>(context, listen: false);
      CurrentPostProvider currentPostProvider =
          Provider.of<CurrentPostProvider>(context, listen: false);

      UserClass? user = userProvider.getUser();

      Map comment = {
        "message": _commentController.text.trim(),
        "userID": {
          "_id": user!.userID,
          "username": user.username,
          "profileURL": user.profileURL,
        },
        "timestamp": DateTime.now().toIso8601String(),
      };

      currentPostProvider.addSingleComment(comment);

      Map addCommentBody = {
        "message": _commentController.text.trim(),
        "userID": user.userID,
        "timestamp": DateTime.now().toIso8601String(),
      };

      _commentController.text = '';

      final addCommentData =
          await PostAPIS.addComment(widget.post.postID!, addCommentBody);
      Map unpackedAddCommentData = unPackLocally(addCommentData);

      if (unpackedAddCommentData["success"] == 1) {
        Fluttertoast.showToast(msg: "Added Comment Successfully!");
      } else {
        Fluttertoast.showToast(msg: "Something went wrong!");
      }
    }
  }

  Future<void> _initialize() async {
    CurrentPostProvider currentPost =
        Provider.of<CurrentPostProvider>(context, listen: false);
    currentPost.resetComments();
    final commentData =
        await PostAPIS.getComments(widget.post.postID.toString());
    Map unpackedCommentData = unPackLocally(commentData);

    if (unpackedCommentData["success"] == 1) {
      currentPost.setComments(unpackedCommentData["unpacked"]["comments"]);
    } else {
      currentPost.toggleWentWrongComments(true);
    }
  }

  @override
  void initState() {
    _initialize();
    super.initState();
  }

  @override
  void dispose() {
    _commentController.clear();
    super.dispose();
  }

  PopupMenuItem commentMenuOption({required bool isCopy, Map? comment}) {
    return PopupMenuItem(
      child: Row(
        children: [
          Icon(isCopy ? Icons.copy : Icons.delete),
          Text(isCopy ? "Copy Text" : "Delete"),
        ],
      ),
      onTap: () {
        if (!isCopy) {
          deleteComment(context, comment!, widget.post);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // print("COMMENT PAGE BUILD");
    CurrentPostProvider currentPost = Provider.of<CurrentPostProvider>(context);
    List commentList = currentPost.comments;

    bool isLoadedComments = currentPost.isCommentsLoaded;
    bool wentWrongComments = currentPost.wentWrongComments;

    commentList.forEach((element) {
      print(element);
    });

    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            UpperWidgetOfBottomSheet(
              backTapHandler: () {
                Navigator.of(context).pop();
              },
              tapHandler: () {},
              toShow: false,
              icon: Icons.stop,
            ),
            wentWrongComments
                ? const Text("Couldn't fetch comments")
                : !isLoadedComments
                    ? const Expanded(child: Center(child: GlobalLoader()))
                    : Expanded(
                        child: Container(
                          padding: const EdgeInsets.only(
                            top: 20,
                            left: 24,
                            right: 24,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(40),
                              topRight: Radius.circular(40),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    "Comments",
                                    style: TextStyle(
                                      fontFamily: "Quicksand",
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0xFFdedede),
                                          blurRadius: 1,
                                          spreadRadius: 0.5,
                                          offset: Offset(0, 1),
                                        )
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(7),
                                    child: Text(
                                      commentList.length.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Expanded(
                                child: RefreshIndicator(
                                  backgroundColor: Colors.white,
                                  color: const Color(0xFF4776E6),
                                  onRefresh: () {
                                    return Future.delayed(
                                      const Duration(seconds: 1),
                                      () {
                                        setState(() {
                                          _initialize();
                                        });
                                      },
                                    );
                                  },
                                  child: !commentList.isNotEmpty
                                      ? const SizedBox()
                                      : _CommentList(commentList),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
            Container(
              margin: const EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: 20,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(
                        top: 1,
                        bottom: 1,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFf5f5fc),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          bottomLeft: Radius.circular(15),
                        ),
                      ),
                      child: TextFormField(
                        controller: _commentController,
                        cursorColor: Colors.black,
                        autofocus: false,
                        decoration: const InputDecoration(
                          hintText: "Comment Here...",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.only(left: 20),
                          hintStyle: TextStyle(
                            color: Color(0xFF404040),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _addComment,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 13,
                      ),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                        ),
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF4776E6),
                            Color(0xFF8E54E9),
                          ],
                          begin: Alignment.bottomLeft,
                          end: Alignment.topRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        CupertinoIcons.location_fill,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  ListView _CommentList(List commentList) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: commentList.length,
      itemBuilder: (ctx, index) {
        bool corruptComment =
            Comment.fromJson(commentList[index]).userID == null;

        return Container(
          margin: const EdgeInsets.only(bottom: 25),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 35,
                width: 35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: NetworkImage(
                      corruptComment
                          ? placeholder
                          : commentList[index]["userID"]["profileURL"],
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      corruptComment
                          ? "Unnamed"
                          : commentList[index]["userID"]["username"].toString(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    SelectableText(
                      commentList[index]["message"],
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // CustomPopupMenu(
                  //     dataset: commentDataset, showOther: isTheSamePerson),
                  Text(
                    timeago.format(
                      DateTime.parse(commentList[index]["timestamp"]),
                    ),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
