import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../theme/app_theme.dart';

class CommentsView extends StatelessWidget {
  final Movie movie;

  const CommentsView({required this.movie, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(movie.title, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Film posteri ve yorumlar
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Film posteri
                    Container(
                      width: 100,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(movie.posterUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Yorumlar
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kullanıcı Yorumları',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Örnek yorum
                          _buildCommentCard(
                            username: 'Kullanıcı1',
                            profileImageUrl: 'https://example.com/profile1.jpg',
                            rating: 8,
                            comment: 'Film harikaydı! Kesinlikle izlenmeli.',
                          ),
                          const SizedBox(height: 8),
                          _buildCommentCard(
                            username: 'Kullanıcı2',
                            profileImageUrl: 'https://example.com/profile2.jpg',
                            rating: 6,
                            comment: 'Fena değildi ama beklentilerimi karşılamadı.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Yorum yap widget'ı
          _buildCommentForm(),
        ],
      ),
    );
  }

  Widget _buildCommentCard({
    required String username,
    required String profileImageUrl,
    required int rating,
    required String comment,
  }) {
    return GestureDetector(
      onTap: () {
        // Yorumun tamamını göstermek için bir dialog açabilirsiniz.
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppTheme.lightGrey,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profil fotoğrafı
            CircleAvatar(
              backgroundImage: NetworkImage(profileImageUrl),
              radius: 24,
            ),
            const SizedBox(width: 8),
            // Yorum içeriği
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppTheme.secondaryGrey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Rating
            Text(
              '$rating/10',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightGrey,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Film hakkında düşündüklerinizi yazın:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Yorumunuzu buraya yazın...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Rating:'),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: 5,
                items: List.generate(
                  10,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1}'),
                  ),
                ),
                onChanged: (value) {
                  // Rating seçimi
                },
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  // Yorum gönderme işlemi
                },
                child: const Text('Gönder'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}