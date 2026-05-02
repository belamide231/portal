using System.Text.Json.Serialization;

namespace AccountModels
{
    public record UserInformationModel (
        string UserId, 
        string Role, 
        string FullName, 
        string StudentId, 
        string Course, 
        string Gmail, 
        string ProfilePic,
        bool IsModerator
    );
}